import sys
import os
sys.path.append(os.path.dirname(__file__))
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from os.path import basename, join
import yaml
from glob import glob
import fire
from multiprocessing import Pool
import pandas as pd
import datetime
import logging
import subprocess
import re
import time
from functools import reduce
from pathlib import Path

logging.basicConfig(format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s',
                    level=logging.DEBUG)

from pipelinerunner.PipelineRunner import read_git_version_from_folder

def getOutputOfCmd(cmd, executable='/bin/bash'):
    '''
    https://blog.csdn.net/wowocpp/article/details/80775650
    '''
    start = time.time()
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, executable=executable)
    out,err = p.communicate()
    end = time.time()
    dict_to_return = {}
    dict_to_return['cmd'] = cmd
    dict_to_return['out'] = out.splitlines()
    dict_to_return['err'] = err
    dict_to_return['start'] = start
    dict_to_return['end'] = end
    dict_to_return['elapse'] = end - start
    dict_to_return['returncode'] = p.returncode
    
    return dict_to_return

def globInFolderInAndGenerateInFolderOut(folder_in, file_type_in_folder_in, folder_out1, \
    operation_for_batch='', operation_for_single='', 
    include_file_in_folder_if_contains='', 
    exclude_file_in_folder_if_contains='DONTUSE', 
    max_process_num=4, overwrite=False, **kargs):
    '''
    glob files in folder_in, and do operation.
    operation should be a shell command str and must contain {file_input} and {folder_out1}. 
    Two modes: operation_for_batch and operation_for_single are exclusive.
    overwrite is currently made unavailable. The downstream pipeline should control not to overwrite the existing output. 
    file_type_in_folder_in: allow "," to seperate multiple possible format. 
    '''
    include_file_in_folder_if_contains = include_file_in_folder_if_contains.strip()
    os.makedirs(folder_out1, exist_ok=True)
    max_process_num = int(max_process_num)
    mpool = Pool(max_process_num)
    fmts = file_type_in_folder_in.replace(' ','').split(',')
    glob_strs = [join(folder_in, '*{}'.format(f)) for f in fmts]
    files_in_folder_in = sorted(set(reduce(lambda x,y:x+y, [glob(glob_str) for glob_str in glob_strs])))

    files_in_folder_in = list(filter(
        lambda x: exclude_file_in_folder_if_contains not in os.path.basename(x.rstrip(os.sep)),
        files_in_folder_in
        ))
    
    files_in_folder_in = list(filter(
        lambda x: include_file_in_folder_if_contains in os.path.basename(x.rstrip(os.sep)),
        files_in_folder_in
        ))
    
    # Log init
    log_dir = folder_out1.rstrip(os.path.sep) + '_log'
    os.makedirs(log_dir, exist_ok=True)
    logger = logging.getLogger(folder_out1)
    log_for_whole_procedure = os.path.join(log_dir, '{}.log'.format(datetime.datetime.now().strftime('%Y%m%d_%H%M%S')))
    file_handler = logging.FileHandler(log_for_whole_procedure)
    file_handler.setLevel(logging.DEBUG)
    logger.addHandler(file_handler)
    start = time.time()
    logger.debug("start at: {}".format(start))

    logger.debug('max_process_num: {}'.format(max_process_num))
    logger.debug('glob_strs is {}'.format(glob_strs))
    logger.debug('files_in_folder_in: {} ... total: {}'.format(files_in_folder_in[:10], len(files_in_folder_in)))
    
    # version capture
    git_version_dir_scripts = read_git_version_from_folder(kargs.get('dir_scripts'))
    # pip packages
    package_versions = getOutputOfCmd('source activate {} && pip freeze'.format(kargs.get('env')))['out']

    logger.debug('git_version_dir_scripts is {}'.format(git_version_dir_scripts))
    logger.debug('package_versions is {}'.format(package_versions))

    # check if previously done
    previously_done = glob(os.path.join(log_dir, '*.success'))
    previously_done = list(map(lambda x:Path(re.sub('.success$','', x)).name, previously_done))
    
    files_in_folder_in_for_running = list(filter(lambda x:Path(x).name not in previously_done, files_in_folder_in))
    logger.debug('files_in_folder_in_for_running: {} ... total: {}'.format(files_in_folder_in_for_running[:10], len(files_in_folder_in_for_running)))
    
    if operation_for_batch and (not pd.isna(operation_for_batch)):
        df_all_files = pd.DataFrame(files_in_folder_in_for_running, columns=['file'])
        path_all_files = '{}{}.files'.format(folder_in.rstrip(os.path.sep), file_type_in_folder_in)
        df_all_files.to_csv(path_all_files, index=False)
        operation_for_all_files = operation_for_batch.format(file_input=path_all_files, folder_out1=folder_out1, **kargs)
        os.system(operation_for_all_files)
    else:
        '''
        recommended to use single sample commands
        '''
        cmds = []
        results_apply_async = []
        for f in files_in_folder_in_for_running:
            # output_file = join(folder_out1, basename(f))
            # if os.path.exists(output_file) and (not overwrite):
            #     continue
            sample_log = '{}/{}_{}.log'.format(log_dir, Path(f).name, datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
            file_to_mark_success = os.path.join(log_dir, Path(f).name) + '.success'
            operation_for_f = \
                'source activate {} && '.format(kargs.get('env')) \
                + operation_for_single.format(file_input=f, folder_out1=folder_out1, **kargs) \
                + ' > {} 2>&1'.format(sample_log) \
                + '&& touch {}'.format(file_to_mark_success)

            cmds.append(operation_for_f)

            results_apply_async.append(mpool.apply_async(getOutputOfCmd, (operation_for_f,)))

        mpool.close()
        mpool.join()

        # get exit code and output tsv
        df_success_or_not = pd.DataFrame.from_dict([r.get() for r in results_apply_async])
        df_success_or_not.insert(0, 'file', files_in_folder_in_for_running)
        
        if df_success_or_not.empty:
            logger.debug('No samples were processed, check if output already exists')
            return
        df_success_or_not.to_csv(log_for_whole_procedure+'.success_or_not.tsv', sep='\t', index=False)

    end = time.time()
    logger.debug("end at: {}".format(start))
    logger.debug("elapse: {}".format(end - start))
    

def parseTableToGlobAndProcess(path_table_for_process, DIR_CANCER, specify_row_index='Must specify. If you want to run all, use all but be careful', \
    include_file_in_folder_if_contains='', exclude_file_in_folder_if_contains='DONTUSE'):
    '''
    path_table_for_process must contain: 
        name, operation_for_batch, operation_for_single,
        folder_in, file_type_in_folder_in,
        folder_out1, folder_out2, ..., folder_out10, opt1, opt2, ..., opt10, 
        env, dir_scripts, author

    '''
    df_process = pd.read_csv(path_table_for_process, sep='\t', encoding='gbk', index_col=0)
    fields_need_to_replace_DIR_CANCER = list(filter(lambda x:'folder' in x, df_process.columns))
    df_process.loc[:,fields_need_to_replace_DIR_CANCER] = df_process.loc[:,fields_need_to_replace_DIR_CANCER].fillna('').applymap(lambda x:x.replace('{DIR_CANCER}', DIR_CANCER))
    if specify_row_index == 'all':
        pass
    else:
        df_process = df_process.loc[specify_row_index:specify_row_index]
    
    for row_index,row in df_process.iterrows():
        print('dealing with {}'.format(row_index))
        globInFolderInAndGenerateInFolderOut(**row.to_dict(), \
            include_file_in_folder_if_contains=include_file_in_folder_if_contains, exclude_file_in_folder_if_contains=exclude_file_in_folder_if_contains)



if __name__ == '__main__':
    # fire.Fire(globInAAndGenerateInB)
    # parseTableToGlobAndProcess('/home/wangb/pipelines/structureunifier/Procedures.tsv',\
    #     '/home/wangb/pipelines/structureunifier/example_cancer', 
    #     specify_row_index='cucim-tile-cupy-macenko-norm')
    fire.Fire(parseTableToGlobAndProcess)
