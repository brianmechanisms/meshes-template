#!/bin/bash

html_safe() {
    local string="$1"
    string=$(echo "$string" | sed -e 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'\''/\&#39;/g')
    echo "$string"
}

mkdir -p ./public
cp index2.html ./public/index.html
mkdir -p ./public/x3ds

touch ./public/.nojekyll
rsync -av images ./public/
rsync -av meshes ./public/
rsync -av site_libs ./public/
mkdir -p ./public/x3d

ORGANIZATION=$1
REPO=$2

temp_file=$(mktemp)  
temp_file_for_sh=$(mktemp)  
temp_file_for_links=$(mktemp) 
sidebar_temp_file=$(mktemp) # main and org level sidebar
sidebar_temp_file_2=$(mktemp) # project sidebar 2
temp_file_x3d=$(mktemp) # project sidebar 2

## Sidebar content for index and org level pages
for dir in ./meshes/*; do
    if [ -d "$dir" ]; then
        dir_name=$(basename "$dir")
        html_safe_dir_name=$(html_safe "$dir_name")
        html_path="${html_safe_dir_name}/index.html"
        echo -n "<li class=\"sidebar-item\"><div class=\"sidebar-item-container\"><a href=\"/${REPO}/$html_path\" class=\"sidebar-item-text sidebar-link\" >$dir_name</a ></div></li>" >> "$sidebar_temp_file"
    fi 
done

# Loop through files in the ./meshes directory
# meshes
# meshes/pacars
# meshes/botarmbots
sidebarItems=$(cat "$sidebar_temp_file")
sed -i "s|{{sidebar}}|$sidebarItems|g" "./public/index.html"
sed -i "s/{{organization}}/$ORGANIZATION/g" "./public/index.html"
sed -i "s/{{repo}}/$REPO/g" "./public/index.html"

rootDir=$(pwd)
for org_dir in ./meshes/*; do
    if [ -d "$org_dir" ]; then
        org_name_full=$(basename "$org_dir")
        org_name=$(html_safe "$org_name_full")
        template_file="./public/${org_name}/index.html"
        mkdir -p "./public/${org_name}"
        cp index2.html "$template_file"

        ## list sidebar items: project files
        echo "" > "$sidebar_temp_file_2"
        for project_dir_path in "$org_dir/"*; do 
            if [ -d "$project_dir_path" ]; then
                project_name=$(basename "$project_dir_path")
                project_dir=$(html_safe "$project_name")
                mkdir -p "./public/${org_name}/${project_dir}"
                #template_file="./public/${org_name}/${project_dir}/index.html"
                html_path="${org_name}/${project_dir}/index.html"
                echo -n "<li class=\"sidebar-item\"><div class=\"sidebar-item-container\"><a href=\"/${REPO}/$html_path\" class=\"sidebar-item-text sidebar-link\" >$project_name</a ></div></li>" >> "$sidebar_temp_file_2"
            fi 
        done

        # sidebarItems_2=$(cat "$sidebar_temp_file_2")
                
        sidebar_content=$(< "$sidebar_temp_file_2")
        awk -v var="$sidebar_content" '{gsub("{{sidebar}}", var)} 1' "$template_file" > temp_file && mv temp_file "$template_file"
        sed -i "s/{{organization}}/$org_name/g" "$template_file"
        sed -i "s/{{repo}}/$REPO/g" "$template_file"
        

        for project_dir_path in "$org_dir/"*; do 
            if [ -d "$project_dir_path" ]; then
                project_name=$(basename "$project_dir_path")
                project_dir=$(html_safe "$project_name")
                mkdir -p "./public/${org_name}/${project_dir}"
                template_file="./public/${org_name}/${project_dir}/index.html"
                cp index.html "${template_file}"

                sed -i "s/{{organization}}/$org_name/" "$template_file"
                sed -i "s/{{repo}}/$REPO/g" "$template_file"
                sed -i "s/{{source}}/$project_name/g" "$template_file"
                # sed -i "s|{{sidebar}}|$sidebarItems_2|g" "$template_file"
                sidebar_content=$(< "$sidebar_temp_file_2")
                awk -v var="$sidebar_content" '{gsub("{{sidebar}}", var)} 1' "$template_file" > temp_file && mv temp_file "$template_file"

                # Loop through files in the directory
                echo "" > "$temp_file"
                echo "#!/bin/bash" > "$temp_file_for_sh"
                echo "" > "$temp_file_for_links"
                for file in "$project_dir_path/"*; do
                    # if [ -f "$file" ]; then
                        filename=$(basename "$file")
                        filename_no_extension="${filename%.*}"
                        extension="${filename##*.}"
                        echo " wget \"https://$ORG_NAME.github.io/$REPO/meshes/${org_name_full}/${project_name}/${filename}\"" >> "$temp_file_for_sh"   

                        if [[ "${extension##*.}" == "obj" ]]; then
                            echo "$file has a '.obj' extension."
                            mkdir -p "$rootDir/public/x3d/${org_name_full}/${project_name}/"
                            # create x3d from template
                            cp "$rootDir/x3dTemplate.x3d" "$rootDir/public/x3d/${org_name_full}/${project_name}/${filename_no_extension}.x3d"

                            obj_content="https://$ORG_NAME.github.io/$REPO/meshes/${org_name_full}/${project_name}/${filename_no_extension}.obj"
                            mtl_content="https://$ORG_NAME.github.io/$REPO/meshes/${org_name_full}/${project_name}/${filename_no_extension}.mtl"
                            x3dFile="$rootDir/public/x3d/${org_name_full}/${project_name}/${filename_no_extension}.x3d"
                            awk -v var="$obj_content" '{gsub("{{obj}}", var)} 1' "$x3dFile" > temp_file && mv temp_file "$x3dFile"
                            awk -v var="$mtl_content" '{gsub("{{mtl}}", var)} 1' "$x3dFile" > temp_file && mv temp_file "$x3dFile"
                        
                        fi
                        
                    # fi
                done
                // remove all
                

                cp "$temp_file_for_sh" "$project_dir_path/download.sh"
                chmod +x "$project_dir_path/download.sh"
                echo "<div class=\"quarto-layout-row quarto-layout-valign-top\"><div class=\"quarto-layout-cell quarto-layout-cell-subref\" style=\"flex-basis: 100%; justify-content: center\" ><div id=\"fig-${download}\" class=\"quarto-figure quarto-figure-center anchored\" ><figure class=\"figure\"><p><a href=\"/$REPO/meshes/${org_name_full}/${project_name}/download.sh\">download.sh</a></p><p></p></figure></div></div></div>" >> "$temp_file" 
                for file in "$project_dir_path/"*; do
                    # if [ -f "$file" ]; then
                        filename=$(basename "$file")
                        filename_no_extension="${filename%.*}"
                        echo "<div class=\"quarto-layout-row quarto-layout-valign-top\"><div class=\"quarto-layout-cell quarto-layout-cell-subref\" style=\"flex-basis: 100%; justify-content: center\" ><div id=\"fig-${filename_no_extension}\" class=\"quarto-figure quarto-figure-center anchored\" ><figure class=\"figure\"><p><a href=\"/$REPO/meshes/${org_name_full}/${project_name}/${filename}\">${filename_no_extension}</a></p><p></p></figure></div></div></div>" >> "$temp_file"   
                        echo "<li> <a href=\"#fig-${filename_no_extension}\" id=\"toc-${filename_no_extension}\" class=\"nav-link active\" data-scroll-target=\"#fig-${filename_no_extension}\" >${filename_no_extension}</a></li>" >> "$temp_file_for_links"   
                        mkdir -p 
                    # fi
                done
                sed -i "s/{{section}}/$(sed 's:/:\\/:g' $temp_file | tr -d '\n')/g" "$template_file"
                sed -i "s/{{links}}/$(sed 's:/:\\/:g' $temp_file_for_links | tr -d '\n')/g" "$template_file"

                # cp "$temp_file_for_sh" "$project_dir_path/download.sh"
                # grep '\obj"$' "$project_dir_path/download.sh"  > objs
                # sed -i 's/^[ ]*wget //' objs
                # mkdir -p 
            fi
        done
    fi
done