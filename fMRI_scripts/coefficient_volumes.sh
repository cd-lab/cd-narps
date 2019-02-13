

# this general form works, now just add loss and RT and divide by group
for sub in individual_glm/glm004_subject*.nii.gz ; do

    # get the id and the group affiliation
    id=$(echo $sub | cut -f 3 -d "_" | tr -dc '0-9')
    group=$(grep $id ../group_assignment.csv | cut -f 2 -d ",")

    echo "Working on ${id} from group ${group}..."

    # get coefficient volumes and distribute them
    if [ $group = "equalIndifference" ] ; then

        echo "EI peep..."

        3dcalc -a ${sub}'[5]' -prefix group_glm/gain_EI/indiv/glm04_sub-${id}_gain.nii.gz -expr 'a'
        3dcalc -a ${sub}'[7]' -prefix group_glm/loss_EI/indiv/glm04_sub-${id}_loss.nii.gz -expr 'a'
        3dcalc -a ${sub}'[3]' -prefix group_glm/RT_EI/indiv/glm04_sub-${id}_RT.nii.gz -expr 'a'

    else

        echo "ER peep..."

        3dcalc -a ${sub}'[5]' -prefix group_glm/gain_ER/indiv/glm04_sub-${id}_gain.nii.gz -expr 'a'
        3dcalc -a ${sub}'[7]' -prefix group_glm/loss_ER/indiv/glm04_sub-${id}_loss.nii.gz -expr 'a'
        3dcalc -a ${sub}'[3]' -prefix group_glm/RT_ER/indiv/glm04_sub-${id}_RT.nii.gz -expr 'a'

    fi

done