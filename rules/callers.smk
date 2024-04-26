def bam_input(wildcards):
    if config["material"] != "RNA":
        tag = "bam"
    else:
        tag = "RNAsplit.bam"

    return expand("mapped/{input_bam}.{tag}",input_bam=wildcards.sample_name,tag=tag)[0]

def lib_ROI_input(wildcards):
    if config["lib_ROI"] != "wgs":
        return config["organism_dna_panel"] #defined in bioroots utilities
    else:
        return config["organism_dict"],

rule haplotypecaller:
    input:  bam = bam_input,
            ref = config["organism_fasta"],
            regions = lib_ROI_input
    output: vcf="germline_varcalls/{sample_name}/haplotypecaller/haplotypecaller.vcf"
    log: "logs/{sample_name}/callers/haplotypecaller.log"
    threads: 5
    resources:
        mem_mb=6000
    params: bamout="germline_varcalls/{sample_name}/haplotypecaller/realigned.bam",
            lib_ROI = config["lib_ROI"] #re-defined in bioroots utilities
    conda: "../wrappers/haplotypecaller/env.yaml"
    script: "../wrappers/haplotypecaller/script.py"

rule vardict:
    input:  bam = bam_input,
            ref = config["organism_fasta"],
            regions = lib_ROI_input
    output: vcf="germline_varcalls/{sample_name}/vardict/vardict.vcf"
    log: "logs/{sample_name}/callers/vardict.log"
    threads: 10
    resources:
        mem_mb=8000
    params:
        AF_threshold=config["min_variant_frequency"],
        lib_ROI=config["lib_ROI"]
    conda: "../wrappers/vardict/env.yaml"
    script: "../wrappers/vardict/script.py"

def strelka_lib_ROI_inputs(wildcards):
    if config["lib_ROI"] != "no":
        return {'regions_gz': config["organism_dna_panel"] + ".gz",
                'regions_tbi': config["organism_dna_panel"] + ".gz.tbi"}
    else:
        return {}

rule strelka:
    input:  unpack(strelka_lib_ROI_inputs),
            bam = bam_input,
            ref = config["organism_fasta"],
    output: vcf = "germline_varcalls/{sample_name}/strelka/strelka.vcf"
    log: "logs/{sample_name}/callers/strelka.log"
    threads: 10
    resources:
        mem_mb=6000
    params: dir = os.path.join(GLOBAL_TMPD_PATH,"germline_varcalls/{sample_name}/strelka"),
            material=config["material"],
            lib_ROI=config["lib_ROI"],
            vcf= os.path.join(GLOBAL_TMPD_PATH,"germline_varcalls/{sample_name}/strelka/results/variants/variants.vcf.gz"),
    conda: "../wrappers/strelka/env.yaml"
    script: "../wrappers/strelka/script.py"

rule varscan:
    input:
        bam = bam_input,
        ref = config["organism_fasta"],
        lib_ROI = lib_ROI_input
    output:
        vcf="germline_varcalls/{sample_name}/varscan/varscan.vcf",
    log: "logs/{sample_name}/callers/varscan.log"
    threads: 1
    resources:
        mem_mb=9000
    params:
        mpileup = "germline_varcalls/{sample_name}/varscan/{sample_name}.mpileup",
        snp="germline_varcalls/{sample_name}/varscan/VarScan2.snp.vcf",
        indel="germline_varcalls/{sample_name}/varscan/VarScan2.indel.vcf"
        #extra = config["varscan_extra_params"],
        # " --strand-filter 0 --p-value 0.95 --min-coverage 50 --min-reads2 8 --min-avg-qual 25 --min-var-freq 0.0005",
    conda: "../wrappers/varscan/env.yaml"
    script: "../wrappers/varscan/script.py"


rule RNA_SplitNCigars:
    input: bam = "mapped/{sample_name}.bam",
           ref = config["fasta_vc"]
    output: bam = "mapped/{sample_name}.RNAsplit.bam",
            bai = "mapped/{sample_name}.RNAsplit.bam.bai",
    log:    run = "logs/{sample_name}/callers/RNA_SplitNCigars.log",
    params: bai = "mapped/{sample_name}.RNAsplit.bai"
    conda:  "../wrappers/RNA_SplitNCigars/env.yaml"
    script: "../wrappers/RNA_SplitNCigars/script.py"












# def mpileup_bam_input(wildcards):
#     if config["material"] != "RNA":
#         tag = "bam"
#     else:
#         tag = "RNAsplit.bam"
#     if wildcards.sample_pair == "tumor":
#         return expand("../input_files/mapped/{tumor_bam}.{tag}",tumor_bam=sample_tab.loc[sample_tab.sample_name == wildcards.sample_name, "sample_name_tumor"],tag=tag)
#     else:
#         return expand("../input_files/mapped/{normal_bam}.{tag}",normal_bam=sample_tab.loc[sample_tab.sample_name == wildcards.sample_name, "sample_name_normal"],tag=tag)
#
# def sample_orig_bam_names(wildcards):
#     if config["calling_type"] == "paired":
#         return {'tumor': expand("{val}",val = sample_tab.loc[sample_tab.sample_name == wildcards.sample_name, "original_sample_name_tumor"])[0], \
#                 'normal': expand("{val}",val = sample_tab.loc[sample_tab.sample_name == wildcards.sample_name, "original_sample_name_normal"])[0]}
#     else:
#         return {'tumor': expand("{val}",val = sample_tab.loc[sample_tab.sample_name == wildcards.sample_name, "original_sample_name_tumor"])[0]}



# rule varscan_single:
#     input:
#         unpack(bam_inputs),
#         ref = expand("{ref_dir}/seq/{ref_name}.fa",ref_dir=reference_directory,ref_name=config["reference"])[0],
#         regions=expand("{ref_dir}/intervals/{lib_ROI}/{lib_ROI}.bed",ref_dir=reference_directory,lib_ROI=config["lib_ROI"])[0],
#     output:
#         vcf="variant_calls/{sample_name}/varscan/VarScan2.vcf",
#     log: "logs/{sample_name}/callers/varscan.log"
#     threads: 1
#     resources:
#         mem_mb=9000
#     params:
#         tumor_pileup = "variant_calls/{sample_name}/varscan/{sample_name}_tumor.mpileup.gz",
#         normal_pileup = "variant_calls/{sample_name}/varscan/{sample_name}_normal.mpileup.gz",
#         snp="variant_calls/{sample_name}/varscan/VarScan2.snp.vcf",
#         indel="variant_calls/{sample_name}/varscan/VarScan2.indel.vcf",
#         extra = config["varscan_extra_params"],
#         # " --strand-filter 0 --p-value 0.95 --min-coverage 50 --min-reads2 8 --min-avg-qual 25 --min-var-freq 0.0005",
#         calling_type = config["calling_type"]
#     conda: "../wrappers/varscan/env.yaml"
#     script: "../wrappers/varscan/script.py"
#
# rule germline_varscan:
#     input:  bam = bam_input,
#             ref=expand("{ref_dir}/seq/{ref_name}.fa",ref_dir=reference_directory,ref_name=config["reference"])[0],
#             regions=expand("{ref_dir}/intervals/{lib_ROI}/{lib_ROI}.bed",ref_dir=reference_directory,lib_ROI=config["lib_ROI"])[0]
#     output: vcf = ADIR+"/varscan/{full_name}.germline.vcf"
#     log:    run = ADIR+"/sample_logs/{full_name}/germline_varscan.log",
#     params: mpileup = ADIR+"/varscan/{full_name}.germline.mpileup",
#             snps = ADIR+"/varscan/{full_name}.germline.snps.vcf",
#             indels = ADIR+"/varscan/{full_name}.germline.indels.vcf"
#     threads: 10
#     conda:  "../wraps/variant_calling/germline_varscan/env.yaml"
#     script: "../wraps/variant_calling/germline_varscan/script.py"