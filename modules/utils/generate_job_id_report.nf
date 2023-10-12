process generate_job_id_report {
    publishDir "${params.outdir}/", mode: 'copy'

    input:
    val step_1a
    val step_1b
    val step_1c
    val step_2
    val step_3
    val step_4
    val step_5_liftover
    val step_5_finemap
    val step_5_cheers
    val step_6_gsea
    val step_6_drug

    output:
    path("protocol-job-links.txt")

    script:
    step_1a_job = step_1a ? "\nStep 1a job path: ${params.cloudos_url}/app/jobs/$step_1a" : "\nStep 1a job path: 'step_1a' was not activated"
    step_1b_job = step_1b ? "\nStep 1b job path: ${params.cloudos_url}/app/jobs/$step_1b" : "\nStep 1b job path: 'step_1b' was not activated"
    step_1c_job = step_1c ? "\nStep 1c job path: ${params.cloudos_url}/app/jobs/$step_1c" : "\nStep 1c job path: 'step_1c' was not activated"
    step_2_job = step_2 ? "\nStep 2 job path: ${params.cloudos_url}/app/jobs/$step_2" : "\nStep 2 job path: 'step_2' was not activated"
    step_3_job = step_3 ? "\nStep 3 job path: ${params.cloudos_url}/app/jobs/$step_3" : "\nStep 3 job path: 'step_3' was not activated"
    step_4_job = step_4 ? "\nStep 4 job path: ${params.cloudos_url}/app/jobs/$step_4" : "\nStep 4 job path: 'step_4' was not activated"
    step_5_liftover_job = step_5_liftover ? "\nStep 5 liftover job path: ${params.cloudos_url}/app/jobs/$step_5_liftover" : "\nStep 5 liftover job path: 'step_5_liftover' was not activated"
    step_5_finemap_job = step_5_finemap ? "\nStep 5 finemapping job path: ${params.cloudos_url}/app/jobs/$step_5_finemap" : "\nStep 5 finemapping job path: 'step_5_finemap' was not activated"
    step_5_cheers_job = step_5_cheers ? "\nStep 5 cheers job path: ${params.cloudos_url}/app/jobs/$step_5_cheers" : "\nStep 5 cheers job path: 'step_5_cheers' was not activated"
    step_6_gsea_job = step_6_gsea ? "\nStep 6 gsea job path: ${params.cloudos_url}/app/jobs/$step_6_gsea" : "\nStep 6 gsea job path: 'step_6_gsea' was not activated"
    step_6_drug_job = step_6_drug ? "\nStep 6 drug2ways job path: ${params.cloudos_url}/app/jobs/$step_6_drug" : "\nStep 6 drug2ways job path: 'step_6_drug' was not activated"
    """
    echo "$step_1a_job" > protocol-job-links.txt
    echo "$step_1b_job" >> protocol-job-links.txt
    echo "$step_1c_job" >> protocol-job-links.txt
    echo "$step_2_job" >> protocol-job-links.txt
    echo "$step_3_job" >> protocol-job-links.txt
    echo "$step_4_job" >> protocol-job-links.txt
    echo "$step_5_liftover_job" >> protocol-job-links.txt
    echo "$step_5_finemap_job" >> protocol-job-links.txt
    echo "$step_5_cheers_job" >> protocol-job-links.txt
    echo "$step_6_gsea_job" >> protocol-job-links.txt
    echo "$step_6_drug_job" >> protocol-job-links.txt
    """
}