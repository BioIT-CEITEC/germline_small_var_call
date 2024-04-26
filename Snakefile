import os
import pandas as pd
import json
from snakemake.utils import min_version

configfile: "config.json"

min_version("5.18.0")
GLOBAL_REF_PATH = config["globalResources"]
GLOBAL_TMPD_PATH = config["globalTmpdPath"]

# Reference processing
#

##### BioRoot utilities #####
module BR:
    snakefile: gitlab("bioroots/bioroots_utilities", path="bioroots_utilities.smk",branch="master")
    config: config

use rule * from BR as other_*

sample_tab = BR.load_sample()

config = BR.load_organism()

# config["material"] = "DNA"
# if config["lib_ROI"] != "wgs" and config["lib_ROI"] != "rna":
#     config["reference"] = config["ref_name"] #defined in bioroots utilities
#     config["organism_fasta"] = config["fasta_vc"]
#     config["organism_dict"] = config["dict_vc"]
# else:
#     if config["lib_ROI"] == "rna":
#         config["material"] = "RNA"
#     config["lib_ROI"] = "wgs"

# ####################################
# # create caller list from table
callers = []
if config["germline_use_strelka"]:
    callers.append("strelka")
if config["germline_use_vardict"]:
    callers.append("vardict")
if config["germline_use_haplotypecaller"]:
    callers.append("haplotypecaller")
if config["germline_use_varscan"]:
    callers.append("varscan")

config["min_callers_threshold"] = min(len(callers),config["min_callers_threshold"])

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
        final_variants = expand("germline_varcalls/{sample_name}.final_variants.tsv", sample_name = sample_tab.sample_name)
