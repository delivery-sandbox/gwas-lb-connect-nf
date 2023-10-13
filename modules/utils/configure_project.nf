process configure_project {
    label "cloudos"

    output:
    env PROJECT_NAME, emit: ch_project_name
    val project_bucket, emit: ch_project_bucket
    val workspace_id, emit: ch_workspace_id

    script:
    user_dir = workflow.workDir.toString().split('/')[1]
    final_project_bucket = workflow.workDir.subpath(0,8).toString()
    project_bucket = 's3://' + user_dir + '/' + final_project_bucket
    project_id = workflow.workDir.subpath(6,7).toString()
    workspace_id = workflow.workDir.subpath("${params.workspace_id_subpath_start}","${params.workspace_id_subpath_end}").toString()
    """
    echo workspace_id ${workspace_id}
    cloudos project list \
        --cloudos-url "${params.cloudos_url}" \
        --apikey "${params.cloudos_api_key}" \
        --workspace-id "${workspace_id}" \
        --disable-ssl-verification
    cat project_list.csv
    PROJECT_NAME=\$(grep -e "${project_id}" project_list.csv | cut -f2 -d",")
    """
}
