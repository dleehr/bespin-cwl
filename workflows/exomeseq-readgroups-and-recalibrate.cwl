cwlVersion: v1.0
class: Workflow
requirements:
  - class: ScatterFeatureRequirement
inputs:
  output_dedup_bam_file: File
  reference_genome: File
  read_group_library: string
  read_group_sample_name: string
  read_group_platform: string
  read_group_platform_unit: string
  # GATK
  GATKJar: File
  knownSites: File[] # vcf files of known sites, with indexing
outputs:
  with_read_groups:
    type: File
    outputSource: add_read_groups/output
  # Recalibration
  recalibration_before:
    type: File
    outputSource: recalibrate_01_analyze/output_baseRecalibrator
  recalibration_after:
    type: File
    outputSource: recalibrate_02_covariation/output_baseRecalibrator
  recalibration_plots:
    type: File
    outputSource: recalibrate_03_plots/output_recalibrationPlots
  recalibrated_reads:
    type: File
    outputSource: recalibrate_04_apply/outputfile_printReads
steps:
  add_read_groups:
    run: ../tools/picard-AddOrReplaceReadGroups.cwl
    in:
      read_group_library: read_group_library
      read_group_sample_name: read_group_sample_name
      read_group_platform: read_group_platform
      read_group_platform_unit: read_group_platform_unit
      input_file: output_dedup_bam_file
    out:
      - output
  # Now recalibrate
  recalibrate_01_analyze:
    run: ../community-workflows/tools/GATK-BaseRecalibrator.cwl
    in:
      GATKJar: GATKJar
      inputBam_BaseRecalibrator: add_read_groups/output
      knownSites: knownSites
      outputfile_BaseRecalibrator:
        default: "recal_data.table"
      reference: reference_genome
    out:
      - output_baseRecalibrator
  recalibrate_02_covariation:
    run: ../community-workflows/tools/GATK-BaseRecalibrator.cwl
    in:
      GATKJar: GATKJar
      inputBam_BaseRecalibrator: add_read_groups/output
      knownSites: knownSites
      bqsr: recalibrate_01_analyze/output_baseRecalibrator
      outputfile_BaseRecalibrator:
        default: "post_recal_data.table"
      reference: reference_genome
    out:
      - output_baseRecalibrator
  recalibrate_03_plots:
    run: ../community-workflows/tools/GATK-AnalyzeCovariates.cwl
    in:
      GATKJar: GATKJar
      inputBam_BaseRecalibrator: add_read_groups/output
      inputTable_before: recalibrate_01_analyze/output_baseRecalibrator
      inputTable_after: recalibrate_02_covariation/output_baseRecalibrator
      outputfile_recalibrationPlots:
        default: "recalibration_plots.pdf"
      reference: reference_genome
    out:
      - output_recalibrationPlots
  recalibrate_04_apply:
    run: ../community-workflows/tools/GATK-PrintReads.cwl
    in:
      GATKJar: GATKJar
      inputBam_printReads: add_read_groups/output
      input_baseRecalibrator: recalibrate_01_analyze/output_baseRecalibrator
      outputfile_printReads:
        default: "recal_reads.bam"
      reference: reference_genome
    out:
      - output_printReads