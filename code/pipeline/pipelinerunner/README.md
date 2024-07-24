# Description

A tool to render template sh by a yaml file and run the rendered sh. The yaml must contain the var output_folder.

What is a template sh? 

A sh with {} encapsulating variable names that is going to be replaced by the names in the yaml.

example.sh:

```
source activate xxx_env
sh {DIR_SCRIPTS}/clean.sh {grain} {output_folder}/grain.cleaned.txt 
python {DIR_SCRIPTS}/grind.py {output_folder}/grain.cleaned.txt {output_folder}/grain.cleaned.grinded.txt 
Rscript {DIR_SCRIPTS}/steam.r {output_folder}/grain.cleaned.grinded.txt {output_folder}/grain.cleaned.grinded.steamed.txt 
python {DIR_SCRIPTS}/add_condiment.py  {output_folder}/grain.cleaned.grinded.steamed.txt {condiment}  {output_folder}/bread.txt

```

example.yaml:

```
output_folder: /data2/wangb/pipelines/makebread/run_by_yaml/
condiment: /data2/wangb/pipelines/makebread/example/mycondiment.txt
grain: /data2/wangb/pipelines/makebread/example/mygrain.txt
```

For complete example, see http://192.168.11.28:30000/Kexuetixi/makebread


# Usage
```
/pipelinerunner/PipelineRunner.py example.sh example.yaml

# For long time operation, use nohup is recommended: 
nohup /pipelinerunner/PipelineRunner.py example.sh example.yaml &

```

