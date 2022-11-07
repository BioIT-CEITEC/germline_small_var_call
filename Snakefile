import os
import pandas as pd
import json
from snakemake.utils import min_version

configfile: "config.json"

min_version("5.18.0")
GLOBAL_REF_PATH = config["globalResources"]

# Reference processing
#
config["material"] = "DNA"
if config["lib_ROI"] != "wgs" and config["lib_ROI"] != "RNA":
    # setting reference from lib_ROI
    f = open(os.path.join(GLOBAL_REF_PATH,"reference_info","lib_ROI.json"))
    lib_ROI_dict = json.load(f)
    f.close()
    config["reference"] = [ref_name for ref_name in lib_ROI_dict.keys() if isinstance(lib_ROI_dict[ref_name],dict) and config["lib_ROI"] in lib_ROI_dict[ref_name].keys()][0]
else:
    config["lib_ROI"] = "no"
    if config["lib_ROI"] == "RNA":
        config["material"] = "RNA"


# setting organism from reference
f = open(os.path.join(GLOBAL_REF_PATH,"reference_info","reference2.json"),)
reference_dict = json.load(f)
f.close()
config["species_name"] = [organism_name for organism_name in reference_dict.keys() if isinstance(reference_dict[organism_name],dict) and config["reference"] in reference_dict[organism_name].keys()][0]
config["organism"] = config["species_name"].split(" (")[0].lower().replace(" ","_")
if len(config["species_name"].split(" (")) > 1:
    config["species"] = config["species_name"].split(" (")[1].replace(")","")


##### Config processing #####
# Folders
#
reference_directory = os.path.join(GLOBAL_REF_PATH,config["organism"],config["reference"])

# Samples
#
sample_tab = pd.DataFrame.from_dict(config["samples"],orient="index")

# if not config["is_paired"]:
#     read_pair_tags = [""]
#     paired = "SE"
# else:
#     read_pair_tags = ["_R1","_R2"]
#     paired = "PE"

callers = config["callers"].split(';')

# DEFAULT VALUES
if not "min_variant_frequency" in config:
    config["min_variant_frequency"] = 0

wildcard_constraints:
    vartype = "snvs|indels",
    sample = "|".join(sample_tab.sample_name),
    lib_name = "[^\.\/]+",
    read_pair_tag = "(_R.)?"

####################################
# SEPARATE RULES
include: "rules/callers.smk"
include: "rules/variant_merging.smk"


####################################
# RULE ALL
rule all:
    input:  
        merged = expand("merged/{sample_name}.variants.tsv", sample_name = sample_tab.sample_name),
        normalized = expand("variant_calls/{sample_name}/{variant_caller}/{variant_caller}.norm.vcf",sample_name = sample_tab.sample_name,variant_caller = callers)

