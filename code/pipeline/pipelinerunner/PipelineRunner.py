#!/usr/bin/env python3
import os
import sys
import yaml
import io

# Parent dir of this py
DIR_RUNNER = os.path.dirname(os.path.abspath(__file__))

def sh(cmd):
    '''
    Run cmd.
    '''
    os.system(cmd)

def read_git_version(path_log_to_get_version, which_line=-1, which_field=1):
    list_log_lines = open(path_log_to_get_version).readlines()
    version = list_log_lines[which_line].split(' ')[which_field]
    del(list_log_lines)
    return version

def read_git_version_from_folder(folder, HEAD_RELATIVE_PATH='.git/logs/HEAD', **kargs):
    version = read_git_version(os.path.join(folder, HEAD_RELATIVE_PATH))
    return version

class PipelineRunner():
    def __init__(self, path_pipeline):
        '''
        path_pipeline should be plain text like the following:
            source activate
            sh {DIR_SCRIPTS}/step1.sh {path_input1} {output_folder}/step1.out > {output_folder}/step1.log 2>&1
            Rscript {DIR_SCRIPTS}/step2.r {path_input2} {output_folder}/{step1.out} {output_folder}/step2.out
            python {DIR_SCRIPTS}/step3.py {output_folder}/step1.out {output_folder}/step2.out {output_folder}/step3.out
        '''
        self.basic_params = {}
        self.basic_params['DIR_SCRIPTS'] = os.path.dirname(os.path.abspath(path_pipeline))
        self.basic_params['pipeline_git_version'] = read_git_version_from_folder(DIR_RUNNER)
        self.basic_params['runner_git_version'] = read_git_version_from_folder(self.basic_params['DIR_SCRIPTS'])

    @staticmethod
    def read_params_from_yaml(file_params, encoding='utf-8'):
        loaded_param_json = yaml.load(io.open(file_params, 'r', encoding=encoding), Loader=yaml.FullLoader)
        return loaded_param_json

    def runPipeline(self, path_yaml, output_yaml_file_name='params.yaml', output_sh_file_name='main.sh', \
        run_or_not=True, exist_ok=False, yaml_encoding='utf-8'):
        '''
        `output_folder` must exists in path_yaml
        '''
        dict_params = self.read_params_from_yaml(path_yaml, encoding=yaml_encoding)
        
        dict_params.update(self.basic_params)

        '''
        Create output folder, record git versions and save yaml
        '''
        output_folder = dict_params['output_folder']
        os.makedirs(output_folder, exist_ok=exist_ok)

        yaml.safe_dump(dict_params, open(os.path.join(output_folder, output_yaml_file_name), 'w'), default_flow_style=False)
        
        print('{} created and parameters saved'.format(output_folder))
        
        '''
        Create sh
        '''
        pipelines = open(path_pipeline).read()
        pipelines_filled = pipelines.format(**dict_params)
        path_final_sh = os.path.join(output_folder, output_sh_file_name)
        with open(path_final_sh, 'w') as fw:
            fw.write(pipelines_filled)

        '''
        Run sh
        '''
        if run_or_not:
            sh('sh {} > {}.log 2>&1'.format(path_final_sh, path_final_sh))


if __name__ == '__main__':
    path_pipeline = sys.argv[1]
    path_yaml = sys.argv[2]
    pipeline_runner = PipelineRunner(path_pipeline)
    pipeline_runner.runPipeline(path_yaml)