cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
    expressionLib:
      $import: ../tools/util_lib.cwl
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: SchemaDefRequirement
    types:
      - $import: ../tools/schemas.cwl

inputs:
  bioclient_config: File
  upload_bucket: string
  job_uuid: string
  annotated_vcf_uuid: string
  annotated_vcf_index_uuid: string
  biotype_priority_uuid: string
  effect_priority_uuid: string
  custom_enst_uuid: string?
  dbsnp_priority_db_uuid: string?
  reference_fasta_uuid: string
  reference_fasta_index_uuid: string
  cosmic_vcf_uuid: string?
  cosmic_vcf_index_uuid: string?
  non_tcga_exac_vcf_uuid: string?
  non_tcga_exac_vcf_index_uuid: string?
  hotspot_tsv_uuid: string?
  gdc_blacklist_uuid: string?
  gdc_pon_vcf_uuid: string?
  gdc_pon_vcf_index_uuid: string?
  nonexonic_intervals_uuid: string?
  nonexonic_intervals_index_uuid: string?
  tumor_only: boolean?
  target_intervals_record:
    type:
      type: array
      items: ../tools/schemas.cwl#indexed_file
  case_uuid: string
  experimental_strategy: string
  tumor_submitter_id: string
  tumor_aliquot_uuid: string
  tumor_bam_uuid: string
  normal_submitter_id: string?
  normal_aliquot_uuid: string?
  normal_bam_uuid: string?
  sequencer:
    type:
      type: array
      items: string
    default: null
  maf_center: string[]
  context_size:
    type: int
    default: 5
  exac_freq_cutoff:
    type: float
    default: 0.001
  min_n_depth:
    type: int
    default: 7
  caller_id: string

outputs:
  raw_aliquot_maf:
    type: File
    outputSource: make_raw_aliquot_maf/output_maf

steps:
  stage_data:
    run: ./subworkflows/stage_data_workflow.cwl
    in:
      bioclient_config: bioclient_config
      annotated_vcf_uuid: annotated_vcf_uuid
      annotated_vcf_index_uuid: annotated_vcf_index_uuid
      biotype_priority_uuid: biotype_priority_uuid
      effect_priority_uuid: effect_priority_uuid
      custom_enst_uuid: custom_enst_uuid
      dbsnp_priority_db_uuid: dbsnp_priority_db_uuid
      reference_fasta_uuid: reference_fasta_uuid
      reference_fasta_index_uuid: reference_fasta_index_uuid
      cosmic_vcf_uuid: cosmic_vcf_uuid
      cosmic_vcf_index_uuid: cosmic_vcf_index_uuid
      non_tcga_exac_vcf_uuid: non_tcga_exac_vcf_uuid
      non_tcga_exac_vcf_index_uuid: non_tcga_exac_vcf_index_uuid
      hotspot_tsv_uuid: hotspot_tsv_uuid
      gdc_blacklist_uuid: gdc_blacklist_uuid
      gdc_pon_vcf_uuid: gdc_pon_vcf_uuid
      gdc_pon_vcf_index_uuid: gdc_pon_vcf_index_uuid
      nonexonic_intervals_uuid: nonexonic_intervals_uuid
      nonexonic_intervals_index_uuid: nonexonic_intervals_index_uuid
      target_intervals_record: target_intervals_record
    out:
      - annotated_vcf
      - biotype_priority
      - effect_priority
      - reference_fasta
      - reference_fasta_index
      - optional_files

  get_file_prefix:
    run: ../tools/make_file_prefix.cwl
    in:
      caller_id: caller_id
      job_uuid: job_uuid
      experimental_strategy: experimental_strategy
    out: [ output ]

  make_raw_aliquot_maf:
    run: ../tools/vcf_to_raw_aliquot_maf.cwl
    in:
      input_vcf: stage_data/annotated_vcf
      output_filename:
        source: get_file_prefix/output 
        valueFrom: $(self + '.raw.maf.gz')
      tumor_only: tumor_only 
      caller_id: caller_id
      src_vcf_uuid: annotated_vcf_uuid
      case_uuid: case_uuid
      tumor_submitter_id: tumor_submitter_id
      tumor_aliquot_uuid: tumor_aliquot_uuid
      tumor_bam_uuid: tumor_bam_uuid
      normal_submitter_id: normal_submitter_id
      normal_aliquot_uuid: normal_aliquot_uuid
      normal_bam_uuid: normal_bam_uuid
      sequencer: sequencer
      maf_center: maf_center
      biotype_priority_file: stage_data/biotype_priority
      effect_priority_file: stage_data/effect_priority
      reference_fasta: stage_data/reference_fasta
      reference_fasta_index: stage_data/reference_fasta_index
      reference_context_size: context_size
      exac_freq_cutoff: exac_freq_cutoff
      min_n_depth: min_n_depth
      custom_enst:
        source: stage_data/optional_files
        valueFrom: $(lookup_optional_file(self, "custom_enst_uuid"))
      dbsnp_priority_db:
        source: stage_data/optional_files
        valueFrom: $(lookup_optional_file(self, "dbsnp_priority_db_uuid"))
      cosmic_vcf:
        source: stage_data/optional_files
        valueFrom: $(lookup_optional_file(self, "cosmic_vcf_uuid"))
      non_tcga_exac_vcf:
        source: stage_data/optional_files
        valueFrom: $(lookup_optional_file(self, "non_tcga_exact_vcf_uuid"))
      hotspot_tsv:
        source: stage_data/optional_files
        valueFrom: $(lookup_optional_file(self, "hotspot_tsv_uuid"))
      gdc_blacklist:
        source: stage_data/optional_files
        valueFrom: $(lookup_optional_file(self, "gdc_blacklist_uuid"))
      gdc_pon_vcf:
        source: stage_data/optional_files
        valueFrom: $(lookup_optional_file(self, "gdc_pon_vcf_uuid"))
      nonexonic_intervals:
        source: stage_data/optional_files
        valueFrom: $(lookup_optional_file(self, "nonexonic_intervals_uuid"))
      target_intervals:
        source: stage_data/optional_files
        valueFrom: $(lookup_optional_file(self, "target_intervals"))
    out: [ output_maf ]
