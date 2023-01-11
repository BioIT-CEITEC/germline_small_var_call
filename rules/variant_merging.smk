
rule merge_variant_callers:
    input:  vcfs = lambda wildcards: expand("germline_varcalls/{sample_name}/{variant_caller}/{variant_caller}.norm.vcf",\
                                            sample_name=wildcards.sample_name,\
                                            variant_caller = callers),
            ref = expand("{ref_dir}/seq/{ref_name}.fa",ref_dir=reference_directory,ref_name=config["reference"])[0],
            dict= expand("{ref_dir}/seq/{ref_name}.dict",ref_dir=reference_directory,ref_name=config["reference"])[0],
    output: not_filtered_vcf = "germline_varcalls/{sample_name}.raw_calls.vcf",
            vcf= "germline_varcalls/{sample_name}.final_variants.vcf",
            tsv = "germline_varcalls/{sample_name}.final_variants.tsv"
    log:    "logs/{sample_name}/merge_variant_callers.log"
    params: min_var_reads_threshold = 5,
            min_callers_threshold = 1
    threads: 1
    conda:  "../wrappers/merge_variant_callers/env.yaml"
    script: "../wrappers/merge_variant_callers/script.py"



rule normalize_variants:
    input:  vcf = "germline_varcalls/{sample_name}/{variant_caller}/{variant_caller}.vcf",
            ref = expand("{ref_dir}/seq/{ref_name}.fa",ref_dir=reference_directory,ref_name=config["reference"])[0],
            dict= expand("{ref_dir}/seq/{ref_name}.dict",ref_dir=reference_directory,ref_name=config["reference"])[0]
    output: vcf = "germline_varcalls/{sample_name}/{variant_caller}/{variant_caller}.norm.vcf"
    log:    "logs/{sample_name}/callers/{variant_caller}_normalization.log"
    threads: 1
    conda: "../wrappers/normalize_variants/env.yaml"
    script: "../wrappers/normalize_variants/script.py"
