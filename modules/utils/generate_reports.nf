process combine_reports {
    label "report"

    publishDir(
        path: { "$params.outdir/MultiQC" },
        pattern: "*.html",
        mode: "copy"
    )

    publishDir(
        path: { "$params.outdir" },
        pattern: "step_*/*",
        mode: "move"
    )

    publishDir(
        path: { "$params.outdir" },
        pattern: "protocol-job-links.txt",
        mode: "copy"
    )

    input:
    path report_dir
    path("step_2_staging/*")
    path("step_3_staging/*")
    path("step_4_staging/*")
    path("step_5_staging/*")
    path("step_6_staging/*")
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
    path "*.html"
    path "step_2/*", optional: true
    path "step_3/*", optional: true
    path "step_4/*", optional: true
    path "step_5/*", optional: true
    path "step_6/*", optional: true
    path("protocol-job-links.txt")

    script:
    was_step2_active = params.step_2 ? "mv step_2_staging step_2" : ""
    was_step3_active = params.step_3 ? "mv step_3_staging step_3" : ""
    was_step4_active = params.step_4 ? "mv step_4_staging step_4" : ""
    was_step5_active = params.step_5 ? "mv step_5_staging step_5" : ""
    was_step6_active = params.step_6 ? "mv step_6_staging step_6" : ""
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
    v2g_report_cmd = params.run_v2g ? "for i in `find -L step_2 -name \"*.svg\"`; do name=`basename \$i .svg | sed 's/-/_/g'`; echo \"\$name='\$i'\" >> file_list.txt; done; echo \"table_smr='\$(find -L step_2 -name \"all_tissues.results\")'\" >> file_list.txt; echo \"forest_pval=${params.forest_pval}\" >> file_list.txt" : "echo ''"
    closest_genes_cmd = params.closest_genes ? "echo \"table_closest_genes='\$(find -L step_2 -name \"*.csv\")'\"  >> file_list.txt" : "echo ''"
    metaxcan_cmd = params.metaxcan ? "echo \"table_multixcan='\$(find -L step_2/smultixcan -name \"*.txt\")'\"  >> file_list.txt" : "echo ''"
    """
    # generate job id report
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

    # generate web combines report
    cp -r ${report_dir}/* .

    # create folder to be able to publish after
    $was_step2_active
    $was_step3_active
    $was_step4_active
    $was_step5_active
    $was_step6_active

    # search files for step 2
    if ${params.step_2}; then
        if [ ! -e "step_2/no_v2g_signals.svg" ]; then
            ${v2g_report_cmd}
        fi
        ${closest_genes_cmd}
        if [ ! -e "step_2/smultixcan/empty_file.txt" ]; then
            ${metaxcan_cmd}
        fi;
    fi

    if ${params.step_2}; then
        cat file_list.txt | tr "\\n" "," | sed 's/,\$//g' > file_list1.txt;
    fi

    # step 3,4
    # at the moment not generating report

    # Generates the report
    if ${params.step_2}; then 
        Rscript -e "rmarkdown::render('report.Rmd', params = list(`cat file_list1.txt`))"
        cp report.html multiqc_report.html
        mv report.html report_multiqc_report.html;
    fi
    """
}