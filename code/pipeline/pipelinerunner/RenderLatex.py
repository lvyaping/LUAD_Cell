#!/usr/bin/env python
#coding=utf-8
import sys
import os
sys.path.append(os.path.dirname(__file__))
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

import jinja2
import yaml
import io
import pandas as pd
from glob import glob
from imp import reload
import CommonFunctionsForText
reload(CommonFunctionsForText)
from CommonFunctionsForText import joinWords, replaceStrByDict

pd.set_option('display.max_rows',None)
pd.set_option('display.max_columns',None)
pd.set_option('max_colwidth',1000)

class LatexRenderer():
    '''
    Read yaml file as var dict to render latex. 
    '''
    def __init__(self, path_yaml_DICT_VARS, dir_output, DICT_REPLACE_SYMBOLS = {
                '>':r'\textgreater',
                '<':r'\textless',
                '>=':r'\geq',
                '<=':r'\leq',
                '%':r'$\%$',
                '^':r'\^{}',
                '%':r'\%',
                '}':r'\}',
                '{':r'\{',
                '_':r'\_',
            }):
        '''
        DICT for special chars in latex.
        '''
        self.DICT_VARS = yaml.load(io.open(path_yaml_DICT_VARS, 'r', encoding="utf-8"))
        self.DICT_REPLACE_SYMBOLS = DICT_REPLACE_SYMBOLS
        self.dir_output = dir_output

    def changeTableFormatForLatex(self, str_latex, format_suffix_for_each_column='p{3cm}'):
        '''
        Example:
        \begin{tabular}{llll} to \begin{tabular}{lp{3cm}lp{3cm}lp{3cm}lp{3cm}}
        '''
        lines = str_latex.split('\n')
        first_line = lines[0]
        print(lines)
        format_original = first_line.split('{')[2].split('}')[0]
        print('format_original', format_original)
        expanded = []
        for c in format_original:
            expanded.append(c + format_suffix_for_each_column) 
        format_adding_suffix = ''.join(expanded)
    #     format_adding_suffix = re.sub('(.)', r'\1'+format_suffix_for_each_column, format_original)
        print(format_adding_suffix)
        format_adding_suffix = r'\begin{tabular}{' + format_adding_suffix + '}'
        lines[0] = format_adding_suffix
        str_latex = '\n'.join(lines)
        return str_latex

    def renderTexByDict(self, path_template, path_after_rendering):
        latex_jinja_env = jinja2.Environment(
            block_start_string = '\BLOCK{',
            block_end_string = '}',
            variable_start_string = '\VAR{',
            variable_end_string = '}',
            comment_start_string = '\#{',
            comment_end_string = '}',
            line_statement_prefix = '%%',
            line_comment_prefix = '%#',
            trim_blocks = True,
            autoescape = False,
            loader = jinja2.FileSystemLoader(os.path.abspath('/'))
        )
        template = latex_jinja_env.get_template(path_template)

        rendered = template.render(**self.DICT_VARS)
        io.open(path_after_rendering, 'w', encoding='utf-8').write(rendered)
        
        
    def generateFigureAccordingToTex(self, tex, tex_out):
        # Note that the tex will be modified if there is \VAR in it. 
        self.renderTexByDict(tex, tex_out)
        output_pdf = tex_out.replace('.tex', '.pdf')
        cropped_pdf = tex_out.replace('.tex', '.crop.pdf')
        shAndAssertSuccess('pdflatex {}'.format(tex_out))
        shAndAssertSuccess('pdfcrop {} {}'.format(output_pdf, cropped_pdf))
        return cropped_pdf


    def renderTableFigureAndManuscript(self, glob_str_for_table_tex_template="Table*txt", \
        glob_str_for_figure_tex_template='Figure*.tex', path_template='Manuscript.tex', 
        path_after_rendering='rendered.tex'):
        
        ## Table
        for table in glob(glob_str_for_table_tex_template):
            df = pd.read_csv(table, sep='\t')
            output = table.replace('.txt', '.tex')
            str_latex = replaceStrByDict(self.changeTableFormatForLatex(df.to_latex(index=False)), self.DICT_REPLACE_SYMBOLS) #.replace(r'\begin{tabular}',r'\begin{tabular}{cp{3cm}cp{3cm}cp{3cm}cp{3cm}}')
            print(str_latex)
            io.open(output, 'w', encoding='utf-8').write(str_latex)
            self.DICT_VARS[table.replace('.txt','')] = str_latex
        
        ## Figure
        for tex in glob(glob_str_for_figure_tex_template):
            self.generateFigureAccordingToTex(tex, os.path.join(self.dir_output, os.path.basename(tex)))
        ## Manuscript
        self.renderTexByDict(path_template=path_template, path_after_rendering=path_after_rendering)

def shAndAssertSuccess(cmd):
    return_code = os.system(cmd)
    return 
    assert return_code == 0, '{} failed with code {}'.format(cmd, return_code)

def main(path_yaml_DICT_VARS, folder_contains_tex, dir_output):
    renderer = LatexRenderer(path_yaml_DICT_VARS, dir_output)
    renderer.renderTableFigureAndManuscript(\
        glob_str_for_table_tex_template=os.path.join(folder_contains_tex, "Table*txt"), 
        glob_str_for_figure_tex_template=os.path.join(folder_contains_tex, 'Figure*.tex'), 
        path_template=os.path.join(folder_contains_tex, 'Manuscript.tex'), 
        path_after_rendering=os.path.join(dir_output, 'rendered.tex'))

if __name__ == '__main__':
    path_yaml_DICT_VARS, folder_contains_tex, dir_output = sys.argv[1:4]
    main(path_yaml_DICT_VARS, folder_contains_tex, dir_output)