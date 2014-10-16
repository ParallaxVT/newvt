
#!/bin/bash

# Usage:
#    ???
#
# Scroll options:
#    scroll=n              -> delete any folder named 'scroll', including any copied from .custom/
#    scroll=y              -> copies the 'scroll' folder from the template directory
#    scroll=k              -> neither copies or removes the 'scroll' folder
#    scroll_more=title     -> add scroll without title
#    scroll_more=notitle   -> idem as custom but without title

# Some paths variables
# VirtualBox - Linux Mint Debian Edition
if [ $HOSTNAME = "debianlaptop" ]; then
    mydrive=/media/sf_e
fi
# GitBash
if [ $HOSTNAME = "RAFALAPTOP" ]; then
    mydrive=/e/
fi
# MinGW
if [ $HOSTNAME = "RafaLaptop" ]; then
    mydrive=/e/
fi
#_krpano tiles
krpano_version="1.17"
if [ $(uname -s) = "Linux" ]; then
    krpath="$mydrive/documents/software/virtual_tours/krpano/krpano_tools/krpanotools-linux-$krpano_version/kmakemultires"
else
    krpath="$mydrive/documents/software/virtual_tours/krpano/krpano_tools/krpanotools\krpanotools-$krpano_version/kmakemultires.exe"
fi
krconfig="-config=$mydrive/documents/software/virtual_tours/krpano/krpano_conf/templates/tv_tiles_2_levels_all_devices.config"

# origin directory paths
orig_dir=$mydrive/virtual_tours/.archives/bin/newvt/src
orig_content=$orig_dir/content
orig_include=$orig_dir/include
orig_html=$orig_dir/html
orig_structure=$orig_dir/structure
orig_devel=$orig_structure/files/devel.xml
# monitor script
config=./vt_conf.sh
# temp
temp_folder=./.src/temp
include_plugin=$temp_folder/include_plugin.temp
include_data=$temp_folder/include_data.temp

echo_done() {
    printf "[ \e[92mdone\e[0m ] ...\n"
}

echo_ok() {
    printf "[  \e[92mok\e[0m  ] $1\n"
}
echo_info() {
    printf "[ \e[96minfo\e[0m ] $1\n"
}

echo_warn() {
    printf "[ \e[93mwarn\e[0m ] $1\n"
}

echo_fail() {
    printf "[ \e[91mfail\e[0m ] $1\n"
    exit 1
}

conf_file_found () {
    if ! [ $HOSTNAME = "RafaelGP" ]; then
        # printf "is c\n"
        # Replace /media/g with /media/c
        sed -i 's/\/media\/g/\/media\/c\/Users\/rafaelgp\/work/g' $config
    else
        # printf "is g\n"
        # Replace /media/c with /media/g
        # sed -i 's/\/media\/c\/Users\/rafaelgp\/work/\/media\/g/g' $config
        sed -i 's/\/media\/e\/Users\/rafaelgp\/work/\/media\/g/g' $config
    fi
    source $config
    if [ -z $timestamp ]; then
        echo_fail "timestamp variable not defined"
        exit 1
    elif [ -z $domain_url ]; then
        echo_fail "domain_url variable not defined"
        exit 1
    elif [ -z $list ]; then
        echo_fail "list variable not defined"
        exit 1
    elif [ -z $crossdomain ]; then
        echo_fail "crossdomain variable not defined"
        exit 1
    else
        log_file=$new_dir/newvt.log
        > $log_file
        printf "vt_conf.sh file found\n" >> $log_file
        printf "FOUND: vt_conf.sh ...\n"
    fi
}

build_config_file () {
    # Set folder paths for the input (jobs/) and the output (virtualtours/) directories
    # If it's a test use test directory as an output directory'
    printf "Is this a test? [y/n]\n"
    read testing
    if [ $testing = "n" ]; then
        # read -e -p "Path to virtual tour output folder: " -i "$mydrive/virtual_tours/" VTPATH
        read -e -p "Path to virtual tour output folder: " VTPATH
        new_dir=$VTPATH
        jobs_dir=$PWD
    else
        new_dir=$mydrive/virtual_tours/.archives/vt_test/output
        jobs_dir=$mydrive/virtual_tours/.archives/vt_test/test_directory
    fi

    # Generate log file
    log_file=$new_dir/newvt.log
    log_file=./newvt.log
    > $log_file
    printf "vt_conf.sh file not found\n" >> $log_file

    # Define config var and create a dir.
    # $config will be difined again in add_structure to add a relative path to it
    > $config

    # Config file has three sections:

    # 1- Folder paths: input and output directories
    cat >> $config << EOF
#!/bin/bash

# ========== Paths ==========
testing=$testing
jobs_dir=$jobs_dir
new_dir=$new_dir
domain_url=http://www.clients.tourvista.co.uk/vt/---/-S-scenes_dir/files
crossdomain=http://www.clients.tourvista.co.uk/crossdomain.xml

EOF
    # 2- Base: plugins that are always inculded in a virtual tour
    base="coordfinder|editor_and_options|global|gyro|movecamera|sa|startup"
    printf "# ========== Base ==========\n" >> $config
    #for d in $orig_include/*; do
    #plugin=$(basename $d)
    #[[ ! $plugin =~ ^($base)$ ]] && continue
    #printf "$plugin=y\n"                >> $config
    #done
    #printf "$plugin=y\n"            >> $config
    printf "coordfinder=y\n"        >> $config
    printf "editor_and_options=y\n" >> $config
    printf "global=y\n"             >> $config
    printf "gyro=y\n"               >> $config
    printf "movecamera=y\n"         >> $config
    printf "sa=y\n"                 >> $config
    printf "startup=y\n"            >> $config
    printf "\n"                     >> $config

    # 3- Optional: There are 2 types.
    printf "# ========== Optional ==========\n" >> $config
    for d in $orig_include/*; do
        optional_plugins=$(basename $d)
        #[[ $optional_plugins =~ ^($base)$ ]] && continue
        if [ $optional_plugins != coordfinder ]; then
            if [ $optional_plugins != editor_and_options ]; then
                if [ $optional_plugins != global ]; then
                    if [ $optional_plugins != gyro ]; then
                        if [ $optional_plugins != movecamera ]; then
                            if [ $optional_plugins != sa ]; then
                                if [ $optional_plugins != startup ]; then
                                    printf "$optional_plugins=n\n"      >> $config
                                fi
                            fi
                        fi
                    fi
                fi
            fi
        fi
    done
    cat >> $config << EOF

# ========== Options ==========
logo_client_name=1
scroll_more=title
timestamp=n
list=y
EOF
    printf "Generated vt_conf.sh without any features\n" >> $log_file
    echo_info "Created FILE: vt_conf.sh"
    printf "Edit vt_conf.sh file and run the script again\n"
    exit 0
}

add_custom_dir() {
    # Create .custom/include directories if there is more than 1 scene (scenes, not pano images)
    # .custom contains custom plugins to be included in every scene
    if [ ! -d $new_dir/.custom ]; then
        printf "\nCREATE FOLDER .custom directory\n" >> $log_file
        mkdir $new_dir/.custom
    else
        printf "\n.custom directory already exists\n" >> $log_file
    fi
    if [ ! -d $new_dir/.custom/html ]; then
        mkdir $new_dir/.custom/html
    fi
    if [ ${#tours_array[@]} -gt "1" ]; then
        if [ ! -d $new_dir/.custom/include ]; then
            mkdir $new_dir/.custom/include
        fi
        # I used to call .custom/ just custom/. So if it exists change the name
        if [ -d $new_dir/custom ]; then
            mv $new_dir/custom $new_dir/.custom
        fi
    fi
}

# -------------------
# STRUCTURE FUNCTIONS
# -------------------

rm_old_xml_files() {
    if [ -d "$scenes_dir" ]; then
        if [ ! -z $1 ]; then
            # Delete all the html files but 'index.html' because it's only generated
            # when the script is run for all the tours
            check_html=$(find $1/* -type f -name "*.html*")
            if [ ! -z "$check_html" ]; then
                find $1/*.html -maxdepth 2 -type f ! -iname "index.html" -exec rm -rf {} \;
            fi
            # Remove any xml file which date stamp is year 2000 onwards
            find $1 -name "tour20*.xml" -exec rm -rf {} \;
            find $1 -name "tour_clean20*.xml" -exec rm -rf {} \;
        else
            echo_warn "rm_old_xml_files() -> \$1 not defined"
            printf "$1"
        fi
    fi
}

add_structure() {

    scenes_dir=$(basename $scenes_dir)
    dest_dir=$new_dir/$scenes_dir
    dest_files=$dest_dir/files
    dest_content=$dest_files/content
    dest_include=$dest_files/include
    dest_scenes=$dest_files/scenes
    dest_devel=$dest_files/devel.xml

    panos_dir=$jobs_dir/.src/panos/$scenes_dir

    # config=$orig_include/vt_conf.sh
    # krpano=$dest_files/tour.xml
    # krpano2=$dest_files/tour_clean.xml

    # temp_folder=$orig_dir/temp/$scenes_dir
    # include_plugin=$temp_folder/include_plugin.temp
    # include_data=$temp_folder/include_data.temp

    mkdir -p $new_dir
    mkdir -p $dest_dir
    # Copy structure. Only files and forders newer than the destination will be created
    # To copy files from the template, delete the destination files
    rsync -zra --update $orig_dir/structure/ $dest_dir

    # Stop if there was a problem copying the files
    if [ $? != 0 ]; then
        echo_fail "Copy files from template FAILED"
        exit 1
    fi

    printf "\n    COPY STRUCTURE TO $dest_dir\n" >> $log_file

    # devel.xml needs to be replaced always
    cp $orig_devel $dest_devel
    cat >> $log_file << EOF
    COPY FILE $orig_devel
    TO $dest_devel

EOF

    # source scene names for .sh files in root dir
    scenes_file=./$scenes_dir'.sh'
    if [ $? != 0 ]; then
        echo_warn "Unable to source scene.sh file"
    fi
    if [ -f $scenes_file ]; then
        source $scenes_file
        printf "    Sourced $scenes_file\n\n" >> $log_file
    else
        echo_warn "File scene.sh NOT FOUND. Creating one"
        > $scenes_file
        order=1
        for eachpano in ${scenes_array[@]} ; do
            printf "scene$order=\"\"\n" >> $scenes_file
            order=$(expr $order + 1)
        done
    fi

    echo_ok "Added FOLDER TREE to $scenes_dir tour"
}

add_temp() {
    mkdir -p ./.src
    mkdir -p $temp_folder
    > $temp_folder/plugins.temp
    printf "\nMake directory $temp_folder\n" >> $log_file
}

remove_temp() {
    rm -r $temp_folder
}

add_scene_names() {
    > $temp_folder/scene_names.temp
    order=1
    for eachpano in ${scenes_array[@]} ; do
        panoname=scene$order
        pageurl=/scene$order/
        cat >> $temp_folder/scene_names.temp << EOF
  <pano name="$eachpano"
        scene="$eachpano"
        pageurl="$pageurl"
        pagetitle="${!panoname}"
        title="${!panoname}"
        custom="$custom"
        />

EOF
        order=$(expr $order + 1)
        printf "    ADDED $panoname TO $temp_folder/scene_names.temp\n" >> $log_file
    done
    printf "\n" >> $log_file
}

add_scene_names_files () {
    if [ ! -d $new_dir/$(basename $scenes_dir)'.sh' ]; then
        > $new_dir/$(basename $scenes_dir)'.sh'
    fi
    for scene in "${scenes_array[@]}"; do
        printf "$scene=\"SceneName\"\n" >> $new_dir/$(basename $scenes_dir)'.sh'
    done
}

check_pano_images() {
    # If variable $wrong_format is not empty,
    # there are files with the wrong format
    # tif files will stop the scrit
    # JPG, JPEG and jpeg files will be coverted to jpg
    wrong_format=$(find $1/* -type f ! -name "*.jpg")
    if [ ! -z "$wrong_format" ]; then
        weird_format=$(find $1/* -type f ! -iname "*.jp*")
        if [ ! -z "$weird_format" ]; then
            echo_fail "File $weird_format has a WRONG FORMAT:"
            exit 1
        else
            echo_info "Convert the file $weird_format to the right format"
            rename -f 's/\.JPG$/\.jpg/' $panos_dir/*
            rename -f 's/\.JPEG$/\.jpg/' $panos_dir/*
            rename -f 's/\.jpeg$/\.jpg/' $panos_dir/*
        fi
    else
        echo_ok "CHECKED pano images: $(basename $1)"
    fi
}

add_scene_tiles() {
    # If scenes directory doesn't exists, create it
    if [ ! -d $dest_scenes ]; then
        mkdir -p $dest_scenes
        printf "\n    Make directory $dest_scenes\n" >> $log_file
    fi
    for filename in ${scenes_array[@]} ; do
        # No need to check if jpg file exists as scenes_array is created basend on jpg files
        panofile=$panos_dir/$filename'.jpg'
        # Create tiles only if there isn't a folder in scenes/ or if it's empty
        if [ -d $dest_scenes/$filename ] && [ "$(ls -A $dest_scenes/$filename)" ]; then
            printf "    $dest_scenes/$filename/ directory is OK\n" >> $log_file
        else
            printf "\n    $dest_scenes/$filename NOT FOUND or EMPTY\n" >> $log_file
            printf "\n    panofile IS:\n    $panofile\n" >> $log_file
            if [ $HOSTNAME = "RafaelGP" ]; then
                # Replace /media/g/ with G:/
                pano_path=$(printf $panofile | sed -e 's/\/media\/g/G\:/g')
            fi
            if [ $HOSTNAME = "RafaLaptop" ]; then
                # Replace /media/c/ with C:/
                pano_path=$(printf $panofile | sed -e 's/\/media\/c/C\:/g')
            fi
            if [ $HOSTNAME = "debian" ]; then
                # Don't do anything
                pano_path=$panofile
            fi
            check_pano_images "$panos_dir"

            printf "    krpath IS:\n    $krpath\n" >> $log_file
            printf "    krconfig IS:\n    $krconfig\n" >> $log_file
            printf "    pano_path IS:\n    $pano_path\n" >> $log_file
            $krpath $krconfig $pano_path

            if [ $? != 0 ]; then
                echo_fail  "Krpano tiles FAILED while processing: $each_scene"
                exit 1
            else
                mv $panos_dir/output/scenes/$filename $dest_scenes
                mv $panos_dir/output/$filename.xml $dest_scenes
                # Replace '/scenes' for '%SWFPATH%/scenes'
                sed -e 's/scenes/\%SWFPATH\%\/scenes/g' $dest_scenes/$filename.xml > $dest_scenes/bck_$filename.xml
                mv $dest_scenes/bck_$filename.xml $dest_scenes/$filename.xml
            fi
            echo_ok "Made TILES: $(basename $scenes_dir)/$filename ..."
            printf "\n    MOVE $panos_dir/output/scenes/$filename TO $dest_scenes\n" >> $log_file
            printf "    MOVE $panos_dir/output/$filename.xml TO $dest_scenes\n" >> $log_file
        fi
    done

    # Delete output dirertory
    if [ -d $panos_dir/output ]; then
        rm -r $panos_dir/output
        printf "\n    DELETE directory  $panos_dir/output/n" >> $log_file
    fi

    # Merge all tiles code
    > $temp_folder/tiles.temp
    for f in $(find $dest_scenes/*.xml -maxdepth 0 -type f ); do
        cat $f >> $temp_folder/tiles.temp
    done
    printf "\n    CREATE FILE $temp_folder/tiles.temp\n" >> $log_file
}

check_scene_tiles() {
    if [ ! "$(ls $dest_scenes/ )" ]; then
        echo_fail "    $dest_scenes/ doesn't contain any folder'\n"
        exit 1
    fi
    if [ ! "$(find $dest_scenes/ -maxdepth 1 -name "*.xml")" ]; then
        echo_fail "    $dest_scenes/ doesn't contain any XML files'\n"
        exit 1
    fi
}

# -------------------
# include_plugin.temp
# -------------------

# Every function embeds an <include /> in include_plugin.temp
# At the end it will host all the <include /> for the added plugins
# devel.xml will have that file enbeded replacing [PLUGINS]

add_include_plugin_and_data() {
    > $include_plugin
    > $include_data
    printf "\n    CREATE file $include_plugin\n" >> $log_file
    printf "    CREATE file $include_data\n\n" >> $log_file
    for D in $(find $orig_include/* -maxdepth 0 -type d ); do
        plugin=$(basename $D)
        plugin_value=${!plugin}
        if [ "$plugin_value" = "y" ]; then
            cp -r $orig_include/$plugin $dest_include
            printf "    COPY FOLDER $orig_include/$plugin \n      TO $dest_include\n" >> $log_file
            # printf "y\n"
        fi
        if [ "$plugin_value" = "n" ]; then
            if [ -d $dest_include/$plugin ]; then
                rm -rf $dest_include/$plugin
                printf "\n    DELETE $dest_include/$plugin\n" >> $log_file
            fi
            # printf "n\n"
        fi
        if [ "$plugin_value" = "k" ]; then
            printf "    KEEP $dest_include/$plugin\n" >> $log_file
            # printf "k\n"
        fi
    done
    printf "\n" >> $log_file
    # Also include any folder manually added to the include/ directory
    # Will be duplicates, but they well be removed in 'add_include_plugin' function
    for dir_added in $(find $dest_include/* -maxdepth 0 -type d); do
        added_plugin=$(basename $dir_added)
        added_plugin_value=${!added_plugin}
        # The precent sign is espaped using the percent sign in printf
        printf '  <include url="%%SWFPATH%%/include/'$added_plugin'/index.xml" />\n'>> $include_plugin
        printf "    KEEP $dest_include/$added_plugin\n" >> $log_file
    done
}

add_plugins_in_custom() {
    # Check if .custom directory exists and is not empty
    if [ -d $new_dir/.custom ] && [ "$(ls -A $new_dir/.custom)" ]; then
        # Check if .custom/include directory exists and it's not empty
        if [ -d $new_dir/.custom/include ] &&  [ "$(ls -A $new_dir/.custom/include)" ]; then
            # Make sure all the xml files have the latest version in the header
            for each_custom_xml_file in $(find ./.custom/include/ -type f  -name "*.xml"); do
                sed -i '/^<krpano/d' $each_custom_xml_file
                sed -i "1i<krpano version=\"$krpano_version\">" $each_custom_xml_file
            done
            # For each directory add a <include/> line to $include_pluging file>
            printf "\n" >> $log_file
            for eachdirectory in $(find $new_dir/.custom/include/* -maxdepth 0 -type d ); do
                cp -r $eachdirectory $dest_include
                printf '  <include url="%%SWFPATH%%/include/'$(basename $eachdirectory)'/index.xml" />\n' >> $include_plugin;
                printf "    ADDED FOLDER $(basename $eachdirectory) FROM .custom/include/\n" >> $log_file
            done
        else
            printf "\n    .custom/include is empty\n" >> $log_file
        fi
    fi

    echo_ok "devel.xml -> Added CUSTOM"
}


add_include_plugin() {
    # Remove duplicated lines
    include_plugin_sort=$temp_folder/include_plugin_sort.temp
    sort -u $include_plugin > $include_plugin_sort
    # Replace the line containing [PLUGINS] with .src/temp/include_plugin_sort.temp
    sed -i -e "/\[PLUGINS\]/r $include_plugin_sort" $dest_devel
    sed -i -e '/\[PLUGINS\]/d' $dest_devel
    echo_ok "devel.xml -> Added PLUGINS"
    printf "\n    ADDED $include_plugin_sort\n       TO $dest_devel\n" >> $log_file
}

# -------------------
# include_data.temp
# -------------------

# Every function adds an <include /> line in the file include_data.temp
# At the end it will host all the <include /> for the added data
# devel.xml will have that file enbeded substituting [DATA]

add_info_btn() {

    if [ $info_btn = "y" ]; then
        # Add a set_sidebar_scene action per scene to content/info_btn.xml
        # Never overwrite content/info_btn.xml!!!
        if [ ! -f $dest_content/info_btn.xml ]; then
            order=1
            > $dest_content/info_btn.xml
            printf "<krpano version=\"$krpano_version\">\n" >> $dest_content/info_btn.xml
            # for f in $(find $dest_scenes/*.xml -maxdepth 0); do
            for eachpano in ${scenes_array[@]} ; do
                actionname=set_sidebar_scene$order
                cat >> $dest_content/info_btn.xml << EOF
  <action name="$actionname">
      set(layer[sidebar_text].html,data:text1);
      set(sidebar_btn, true);
  </action>

EOF
                order=$(expr $order + 1)
            done
            printf "</krpano>\n" >> $dest_content/info_btn.xml
            echo_ok "Created FILE: info_btn.xml"
        fi
        # Add some data with text per scene to content/info_btn_text.xml
        if [ ! -f $dest_content/info_btn_text.xml ]; then
            order=1
            printf "<krpano version=\"$krpano_version\">\n" >> $dest_content/info_btn_text.xml
            # for f in $(find $dest_scenes/*.xml -maxdepth 0); do
            for eachpano in ${scenes_array[@]} ; do
                textname=text$order
                texttitle="Scene $order text"
                cat >> $dest_content/info_btn_text.xml << EOF
  <data name="$textname">
    <h2>$texttitle</h2><br/>
    <br/><p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>
  </data>

EOF
                order=$(expr $order + 1)
            done
            printf "</krpano>\n" >> $dest_content/info_btn_text.xml
            echo_ok "Created FILE: info_btn_text.xml"
        fi
    fi
}

add_sa() {
    # Backwards compatibility: delete file content/sa.xml if exists
    if [ -f $dest_content/sa.xml ]; then
        rm $dest_content/sa.xml
    fi
    # Always overwrite content/panolist.xml!!!
    > $dest_content/panolist.xml
    printf '<krpano>\n\n' >> $dest_content/panolist.xml
    printf '  <layer name="panolist" keep="true">\n\n[SCENE_NAMES]\n' >> $dest_content/panolist.xml
    printf '  </layer>\n\n</krpano>\n' >> $dest_content/panolist.xml
    # Replace the line containing [SCENE_NAMES] with the scene names in temp/scene_names.temp
    sed -i -e "/\[SCENE_NAMES\]/r $temp_folder/scene_names.temp" $dest_content/panolist.xml
    sed -i -e '/\[SCENE_NAMES\]/d' $dest_content/panolist.xml
    echo_ok "Created FILE: content/panolist.xml"
    printf "\n    COPY FILE $orig_content/panolist.xml\n      TO $dest_content/panolist.xml\n" >> $log_file
}

add_movecamera_coords()  {
    # Never overwrite content/coord.xml!!!
    if [ ! -f $dest_content/coord.xml ]; then
        order=1
        > $dest_content/coord.xml
        printf "<krpano version=\"$krpano_version\">\n" >> $dest_content/coord.xml
        printf "\n    CREATE FILE $dest_content/coord.xml\n" >> $log_file
        for eachpano in "${scenes_array[@]}"; do
            cat >> $dest_content/coord.xml << EOF
  <action name="movecamera_$eachpano">movecamera(0,0);</action>
EOF
            order=$(expr $order + 1)
            printf "   ADD movecamera_$eachpano\n   TO $dest_content/coord.xml" >> $log_file
        done
        echo_ok "Created FILE: content/coord.xml"
        printf "</krpano>\n"  >> $dest_content/coord.xml
    fi
}

add_logo_client() {
    if [ $logo_client = "y" ]; then
        # If $client_logo_name variable is not defined in vt_conf.sh
        if [ -z $logo_client_name ]; then
            sed -i "s/CLIENTNAME/other/g" $dest_include"/logo_client/index.xml"
            printf "    ADD PLUGIN: logo client - other\n" >> $log_file
        else
            # Possible values for variable client_logo_name:
            # 1 - Creare
            # 2 - Addoctor
            # 3 - Llama Digital
            if [ $logo_client_name = "1" ]; then
                sed -i "s/CLIENTNAME/creare/g" $dest_include"/logo_client/index.xml"
            fi
            if [ $logo_client_name = "2" ]; then
                sed -i "s/CLIENTNAME/addoctor/g" $dest_include"/logo_client/index.xml"
            fi
            if [ $logo_client_name = "3" ]; then
                sed -i "s/CLIENTNAME/llama/g" $dest_include"/logo_client/index.xml"
            fi
            printf "    ADD PLUGIN: logo client - option $logo_client_name\n" >> $log_file
        fi
        echo_ok "Added PLUGIN: logo client"
    fi
}

add_hotspots() {
    if [ "$hotspots" = "y" ]; then
        if [ ${#scenes_array[@]} -gt "1" ]; then
            # Never overwrite content/hs.xml
            if [ ! -f $dest_content/hs.xml ]; then
                > $dest_content/hs.xml
                printf "<krpano version=\"$krpano_version\">\n"  >> $dest_content/hs.xml
                order=1
                for f in $(find $dest_scenes/*.xml -maxdepth 0); do
                    hs_action=add_hs_scene$order
                    scene_no=scene$order
                    cat >> $dest_content/hs.xml << EOF
  <action name="$hs_action">
    hs(up, scene, get(layer[panolist].pano[scene].title),0,0,0,0);
  </action>

EOF
                    order=$(expr $order + 1)
                done
                printf "</krpano>\n"  >> $dest_content/hs.xml
            fi
            printf "\n    ADD PLUGIN: hotspots\n" >> $log_file
            echo_ok "Added PLUGIN: hotspots"
            # if $hotspots = "n" delete include/hs and content/hs.xml
        else
            if [ -f $dest_content/hs.xml ]; then
                rm $dest_content/hs.xml
            fi
            if [ -d $dest_include/hotspots ]; then
                rm -r $dest_include/hotspots
                sed -i -e '/hotspots\/index.xml/d' $dest_devel
            fi
            printf "    REMOVE PLUGIN: hotspots (Only 1 scene)\n" >> $log_file
            echo_ok "Deleted PLUGIN: hotspots (Only 1 scene)"
        fi
    fi
}

remove_scroll () {
    if [ -f $dest_content/scroll.xml ]; then
        rm $dest_content/scroll.xml
    fi
    if [ -d $dest_include/scroll ]; then
        rm -r $dest_include/scroll
        sed -i -e '/scroll\/index.xml/d' $dest_devel
    fi
    printf "    REMOVE PLUGIN: scroll\n" >> $log_file
}

add_scroll () {
    number_of_scenes=${#scenes_array[@]}
    if [ "$scroll" != "n" ]; then
        if [ -z $scroll_more ]; then
            echo_warn "scroll_more variable is not defined."
        else
            if [ "$scroll_more" = "title" ]; then
                scroll_swf='scroll_'$number_of_scenes'_title'
            fi
            if [ "$scroll_more" = "notitle" ]; then
                scroll_swf='scroll_'$number_of_scenes
            fi
            if [ ${#scenes_array[@]} -gt "1" ]; then
                echo_ok "Added PLUGIN: scroll - $number_of_scenes scenes"
                printf "\n    ADD PLUGIN: scroll - $number_of_scenes scenes\n" >> $log_file
                add_scroll_data
            else
                remove_scroll
            fi
        fi
    fi
}

add_scroll_data() {
    # Replace the word [SWF_FILE] with the swf file name, in include/scroll/index.xml
    sed -i "s/\[SWF_FILE\]/$scroll_swf/g" $dest_include'/scroll/index.xml'
    # Copy the corresponding swf file for the number of scenes
    cp -r $orig_content'/scroll/'$scroll_swf.swf  $dest_include'/scroll'

    # Make content/scroll_thumbs/ directory if doesn't exists
    if [ ! -d $dest_content'/scroll_thumbs' ]; then
        mkdir $dest_content'/scroll_thumbs'
    fi
    # Always overwrite content/scroll.xml
    > $dest_content/scroll.xml
    order=1
    printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" >> $dest_content/scroll.xml
    printf "<!-- This file is generated automatically -->\n\n" >> $dest_content/scroll.xml
    printf "<content>\n\n" >> $dest_content/scroll.xml
    for file_name in ${scenes_array[@]}; do
        cat >> $dest_content/scroll.xml << EOF
  <item>
    <path>files/content/scroll_thumbs/$file_name.jpg</path>
    <foldername>$file_name</foldername>
    <data>${!file_name}</data>
    <type>image</type>
    <order>$order</order>
  </item>

EOF
        # Make a thumbnail for each pano, only if it doesn't exists already
        if [ ! -f $dest_content'/scroll_thumbs/'$file_name'.jpg' ]; then
            convert $panos_dir/$file_name'.jpg' -resize 420x210^ -gravity center -extent 200x120 $dest_content'/scroll_thumbs/'$file_name'.jpg'
            printf "    CREATE THUMBNAIL: $content/scroll_thumbs/$file_name.jpg\n" >> $log_file
        fi
        order=$(expr $order + 1)
    done
    printf "</content>\n" >> $dest_content/scroll.xml

    # Duplicate scroll.xml and scroll_thumbs to make it work in devel mode
    if [ ! -d $dest_dir/devel ]; then
        mkdir $dest_dir/devel
    fi
    if [ ! -d $dest_dir/devel/files ]; then
        mkdir $dest_dir/devel/files
    fi
    if [ ! -d $dest_dir/devel/files/content ]; then
        mkdir $dest_dir/devel/files/content
    fi
    if [ ! -d $dest_dir/devel/files/scroll_thumbs ]; then
        cp -r $dest_content/scroll_thumbs $dest_dir/devel/files/content/
    fi
    if [ ! -f $dest_dir/devel/files/scroll.xml ]; then
        cp -r $dest_content/scroll.xml $dest_dir/devel/files/content/
    fi

    printf "    ADD FILE: content/scroll.xml\n" >> $log_file
}

add_plugins_data() {

    # Make sure all the xml files, apart from scroll.xml, have the latest version in the header
    for f in $(find $dest_content/*.xml ! -iname "scroll.xml") ; do
        sed -i '/^<krpano/d' $f
        sed -i "1i<krpano version=\"$krpano_version\">" $f
    done
    for f in $dest_content/*.xml; do
        # Get rid off the path and the extension
        file_name=$(basename "$f")
        extension="${file_name##*.}"
        file_name="${file_name%.*}"
        printf '  <include url="%%SWFPATH%%/content/'$file_name'.xml" />\n' >> $include_data
    done

    # Replace the line containing [DATA] with content
    sed -i -e "/\[DATA\]/r $include_data" $dest_devel
    sed -i -e '/\[DATA\]/d' $dest_devel

    echo_ok "devel.xml -> Added DATA"
    printf "\n    ADD $include_data\n    TO $dest_devel\n" >> $log_file

    # Replace the line containing [TILES] with content in temp/each_tiles_files.temp
    # I haven't created tiles.xml because that would add <include url="scenes/scene1.xml" />
    # and then the tiles path would be relative to devel.xml and it'd be
    # a wrong path (/files/scenes/scenes/scene1/...)
    > $temp_folder/all_tiles_files.temp
    # for each_tiles_file in $(find $dest_scenes/*.xml -maxdepth 0 ); do
    #     printf '  <include url="%%SWFPATH%%/scenes/'$(basename $each_tiles_file)'" />' >> $temp_folder/all_tiles_files.temp
    # done
    for each_tiles_file in ${scenes_array[@]} ; do
        printf '  <include url="%%SWFPATH%%/scenes/'$each_tiles_file'.xml" />\n' >> $temp_folder/all_tiles_files.temp
    done
    sed -i -e "/\[TILES\]/r $temp_folder/all_tiles_files.temp" $dest_devel
    sed -i -e '/\[TILES\]/d' $dest_devel

    echo_ok "devel.xml -> Added TILES"
    printf "    ADD $temp_folder/tiles.temp\n    TO $dest_devel\n" >> $log_file
}

# -------------------
# tour.xml
# -------------------

# tour.xml is made stripping out devel.xml
# Extract the urls form devel.xml, discarting the lines containing 'scenes''
# Embed the files corresponding to each url
# Embed tiles code form temp/tiles.temp
# Delete any krpano tags
# Then add krpano tags one at the top and one at the bottom

add_tour() {
    tour_file=$dest_files/tour.xml
    # Copy devel.xml replacing any existing one
    cp $dest_devel $temp_folder"/devel1.temp"
    > $tour_file
    # Make a temp file with all the files url's
    grep -o 'url=['"'"'"][^"'"'"']*['"'"'"]' $temp_folder"/devel1.temp" > $temp_folder"/devel2.temp"
    # Delete lines containing 'editor_and_options'
    sed -e '/editor_and_options/d' $temp_folder/devel2.temp > $temp_folder/devel3.temp
    # Delete lines containing 'scene'
    sed -e '/scenes/d' $temp_folder/devel3.temp > $temp_folder/devel4.temp
    # Strip off everything to leave just the url's'
    sed -e 's/^url=["'"'"']//' -e 's/["'"'"']$//' $temp_folder"/devel4.temp" > $temp_folder"/devel5.temp"
    # Delete %SWFPATH%
    sed -i 's/%SWFPATH%//g' $temp_folder/devel5.temp
    # Delete the line containing the coordinates finder
    sed -i '/coordfinder/d' $temp_folder/devel5.temp

    # Merge all the files into tour.xml
    while read line; do
        cat $dest_files$line >> $tour_file
        # printf $dest_files$line\n
        # printf $line\n
    done < $temp_folder"/devel5.temp"
    printf "\n    ADD $temp_folder/devel5.temp\n    TO $tour_file\n" >> $log_file

    # Merge all tiles code
    > $temp_folder/tiles.temp
    for f in $(find $dest_scenes/*.xml -maxdepth 0 -type f ); do
        cat $f >> $temp_folder/tiles.temp
    done
    printf "\n    CREATE FILE $temp_folder/tiles.temp\n" >> $log_file

    # Add tiles code
    cat $temp_folder/tiles.temp >> $tour_file
    printf "\n    ADD $temp_folder/tiles.temp\n    TO $tour_file\n" >> $log_file

    # Delete all the lines beginning with <?xml, <krpano </krpano
    sed -i '/^<?xml/d' $tour_file
    sed -i '/^<krpano/d' $tour_file
    sed -i '/^<\/krpano/d' $tour_file

    echo_ok "tour.xml -> krpano tags removed"

    # Add krpano tags at the beginning of tour.xml
    sed -i "1i<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<krpano version=\"$krpano_version\" showerrors=\"false\">" $tour_file

    # Add closing krpano tag at the end of tour.xml and tour_clean.xml
    printf "</krpano>\n" >> $tour_file

    echo_ok "tour.xml -> New krpano tags added"

    # Delete dos new line
    # sed -i 's///g' $tour_file

    # Delete empty lines
    sed -i '/^$/d' $tour_file

    # Delete commented lines
    sed -i '/-->/d' $tour_file

    # Delete indentation
    sed -i -r 's/^[[:blank:]]+//g' $tour_file

    # Delete empty spaces around any = signs
    sed -i 's/\ *=\ */=/g' $tour_file

    echo_ok "tour.xml ->  Empty lines, comments and indentation removed"

    echo_ok "Created FILE: tour.xml"
}

add_tour_clean() {
    tour_clean="$dest_files/tour_clean.xml"
    cp $tour_file $tour_clean
    # Delete the line with <krpnano at the beginning
    sed -i '/^<krpano/d' $tour_clean
    # Add krpano tag with onstart action on line number 2
    # I think we still need onstart-activatepano to ensure backward compatibility
    sed -i "2i<krpano version=\"$krpano_version\" showerrors=\"false\" onstart=\"activatepano(scene1);\">" $tour_clean
    echo_ok "Created FILE: tour_clean.xml"
}

set_crossdomain() {
    source $config
    sed -i "s|\[SETCROSSDOMAIN\]|$crossdomain|g" $tour_file
    echo_ok "Set $crossdomain"
    # Remove any orphan crossdomain.xml files
    find $dest_files/* -name "crossdomain.xml" -exec rm -rf {} \;
}

add_plugins_dir() {
    # Get which plugins are loaded in tour.xml
    awk '/\/plugins\// {sub(/.*\//, ""); sub(/(\);|")?$/, ""); arr[$0] = $0} END {for (i in arr) print arr[i]}' $tour_file > $temp_folder/plugins_list.temp
    # Build an array with these plugins
    declare -a plugins_array=()
    while read line; do
        plugins_array=( "${plugins_array[@]}" "$line")
    done < $temp_folder/plugins_list.temp
    plugins_array+=('options.swf')
    plugins_array+=('editor.swf')
    plugins_array+=('textfield.swf')
    # Are or delete plugins depending if they are loaded by the tour
    for each_plugin in $(find $orig_dir/plugins/* -maxdepth 0 -type f); do
        plugin_file=$(basename $each_plugin)
        case "${plugins_array[@]}" in
            *"$plugin_file"*)
                cp $each_plugin $dest_files/plugins/
                ;;
            *)
                if [ -f $dest_files/plugins/$plugin_file ]; then
                    rm $dest_files/plugins/$plugin_file
                fi
                ;;
        esac
    done
    # Delete any files in $dest_dir/plugins that doesn't exist in $orig_dir/plugins
    for each_plugin_item in $(find $dest_files/plugins/* -maxdepth 0 -type f); do
        if [ ! -f $orig_dir/plugins/$(basename $each_plugin_item) ]; then
            rm $each_plugin_item
        fi
    done
    echo_ok "Removed unused plugins"
}

count_files() {
    printf "[\e[92m$1 of ${#scenes_array[@]}\e[0m] $2\r"
    if [ $counter -lt ${#scenes_array[@]} ]; then
        counter=$(expr $counter + 1)
    fi
}

add_html() {
    source $config
    printf "\n" >> $log_file
    # Scenes
    counter="1"
    for scene_item in "${scenes_array[@]}"; do
        cp -r $orig_dir/html/scene.html $dest_dir/$scene_item.html
        sed -i "s/SCENENAME/$scene_item/g" $dest_dir/$scene_item.html
        sed -i "s|files|$domain_url|g" $dest_dir/$scene_item.html
        printf "Made $scene_item.html file\n" >> $log_file
        count_files "$counter" "Created scenes HTML FILE"
    done
    echo_ok "Created scenes HTML files"
    # Devel
    cp -r $orig_dir/html/devel $dest_dir/
    for devel_item in $(find $dest_dir/devel/*.html); do
        sed -i "s/SCENENAME/${scenes_array[0]}/g" $dest_dir/devel/$(basename $devel_item)
    done
    echo_ok "Created devel HTML files"
    # Devel html files will be named devel/1.html, devel/2.html, etc...
    # This way it's easier to change between scenes
    # mv $dest_dir/devel/devel.html $dest_dir/devel/1.html
    counter="1"
    for scene_devel_item in "${scenes_array[@]}"; do
        scene_counter=$(expr $counter - 1)
        cp -r $orig_dir/html/devel.html $dest_dir/devel/$counter.html
        sed -i "s/SCENENAME/${scenes_array[$scene_counter]}/g" $dest_dir/devel/$counter.html
        printf "    Made devel/$scene_counter.html file\n" >> $log_file
        count_files "$counter" "Created devel scenes HTML file"
    done
    echo_ok "Created devel scenes HTML files"
}

add_html_in_custom() {
    # Check if .custom/html directory exists and it's not empty
    if [ -d $new_dir/.custom/html/$scenes_dir ] && [ "$(ls -A $new_dir/.custom/html/$scenes_dir)" ]; then
        for eachhtmlfile in $(find $new_dir/.custom/html/$scenes_dir/* -maxdepth 0 -name "*.html" ); do
            cp $eachhtmlfile $dest_dir
        done
    fi
    echo_ok "Added HTML files in custom"
}

add_timestamp() {
    if [ $timestamp = "y" ]; then
        timestamp=$(date "+%Y%m%d%H%M%S").xml
        for each_tour_xml in $(find . -name tour.xml); do
            # Get rid off the extension
            extension="${each_tour_xml##*.}"
            each_tour_xml="${each_tour_xml%.*}"
            mv  $each_tour_xml.xml $each_tour_xml$timestamp
            # printf "$each_tour_xml.xml -> $each_tour_xml$timestamp\n"
        done
        for each_tour_clean_xml in $(find . -name tour_clean.xml); do
            # Get rid off the extension
            extension="${each_tour_clean_xml##*.}"
            each_tour_clean_xml="${each_tour_clean_xml%.*}"
            mv  $each_tour_clean_xml.xml $each_tour_clean_xml$timestamp
            # printf "$each_tour_clean_xml.xml -> $each_tour_clean_xml$timestamp\n"
        done
        for each_html_file in $(find . -name "*.html"); do
            sed -i "s/tour_clean.xml/tour_clean$timestamp/g" $each_html_file
            sed -i "s/tour.xml/tour$timestamp/g" $each_html_file
        done
        echo_ok "Added TIME-STAMP"
    fi
}

add_version() {
    for each_xml_file in $(find $scenes_dir/files/ -type f  -name "*.xml"); do
        sed -i "s/<krpano>/<krpano version=\"$krpano_version\">/g" $each_xml_file
    done
    echo_info "Krpano VERSION: $krpano_version"
}

add_list() {
    if [ $list = "y" ]; then

        index_file="./index.html"
        src="./.src/generate_html"
        temp_dir="$src/temp"
        template_file="$src/template.html"
        content_file="$temp_dir/content"

        # Get the template
        cp -r $orig_dir/generate_html/ $src
        # Download style.css from tourvista
        if [ ! -f "./style.css" ]; then
            # wget http://www.tourvista.co.uk/css/style.css
            cp "./.src/generate_html/style.css" "./"
        fi

        cp $template_file $index_file
        mkdir -p $temp_dir
        > $content_file
        printf "List file contains:\n" >> $log_file
        for tour in .src/panos/*; do
            tour_name="$(basename $tour)"
            printf "    $tour_name\n" >> $log_file
            tour_title="${tour_name//_/ }"
            all_brands_array=( $tour_title )
            tour_title="${all_brands_array[@]^}"
            temp_file="$temp_dir/tour_$tour_name"
            > $temp_file
            printf "<h4><a href=\"$tour_name/index.html\">$tour_title</a></h4>\n" >> $temp_file
            printf "<ul>\n" >> $temp_file
            for scene_html in ./.src/panos/$tour_name/*; do
                scene_name="$(basename $scene_html)"
                extension="${scene_name##*.}"
                scene_name="${scene_name%.*}"
                printf "      $scene_name\n" >> $log_file
                scene_fancy_name="${scene_name//_/ }"
                all_words_array=( $scene_fancy_name )
                scene_fancy_name="${all_words_array[@]^}"
                printf "<li><a href=\"$tour_name/$scene_name.html\">$scene_fancy_name</a></li>\n" >> $temp_file
            done
            printf "</ul>\n" >> $temp_file

            cat $temp_dir/tour_$tour_name >> $content_file

            cp $template_file ./$tour_name/index.html

            sed -i "s/$tour_name\///g" "$temp_dir/tour_$tour_name"
            sed -i -e "/\[CONTENT\]/r $temp_dir/tour_$tour_name" ./$tour_name/index.html
            sed -i -e '/\[CONTENT\]/d' ./$tour_name/index.html
            sed -i -e 's/<h4><a href="index.html">/<h4>/g' ./$tour_name/index.html
            sed -i -e 's/<\/a><\/h4>/<\/h4>/g' ./$tour_name/index.html
            sed -i -e 's|\.\/style.css|\.\.\/style.css|g' ./$tour_name/index.html
        done

        sed -i -e "/\[CONTENT\]/r $content_file" $index_file
        sed -i -e '/\[CONTENT\]/d' $index_file

        rm -r $temp_dir
        echo_ok "Added HTML LIST"
    fi
}

start () {
    add_temp
    mkdir -p $temp_folder
    mkdir -p ./.src/panos
    printf "\norig_dir is: $orig_dir\n" >> $log_file
    printf "new_dir is: $new_dir\n" >> $log_file
    printf "jobs_dir is: $jobs_dir\n" >> $log_file

    tours_array=()
    # To run the script for a particular tour, enter its folder name as a param
    # Any trailing back slash at the end is automatically removed
    if [ ! -z $1 ]; then
        declare -a tours_array=( ${1%/})
        # Stop the script if the given directory doesn't exist
        if [ ! -d ".src/panos/$1" ]; then
            echo_fail ".src/panos/$1 directory NOT FOUND"
            exit 1
        fi
    else
        if [ ! -d ".src/panos" ]; then
            echo_fail ".src/panos directory NOT FOUND"
            exit 1
        else
            if [ "$(ls -A $jobs_dir/.src/panos/)" ]; then
                for each_tour in $(find $jobs_dir/.src/panos/* -maxdepth 0 -type d ); do
                    each_tour=$(basename "$each_tour")
                    tours_array=( "${tours_array[@]}" "$each_tour")
                done
            else
                mkdir $jobs_dir/.src/panos/$(basename $jobs_dir)
                printf "         Folder 'tour' has been created\n"
                echo_fail "There are no Tour folders in .src/panos/"
                exit 1
            fi
        fi
    fi

    add_custom_dir

    # Let me khow how many tours are in total
    if [ ${#tours_array[@]} = 1 ]; then
        printf "\nThere is only ${#tours_array[@]} tour: ${tours_array[@]}\n" >> $log_file
    else
        printf "\nThere are ${#tours_array[@]} tours:\n" >> $log_file
        for eachitem in ${tours_array[@]} ; do
            printf "    $eachitem\n" >> $log_file
        done
    fi

    for scenes_dir in "${tours_array[@]}"; do
        # Create a folder for each tour in .src/custom/html
        # Thew will containt html files to replace the default ones
        mkdir -p $new_dir/.custom/html/$scenes_dir
        # Add Tour header to log_file
        printf "TOUR NAME: $scenes_dir\n"
        printf "\n# -------------------------------\n" >> $log_file
        printf "# TOUR: $scenes_dir\n" >> $log_file
        printf "# ---------------------------------\n" >> $log_file

        scenes_array=()
        # Make sure the tour folder is not empty
        if [ "$(ls -A $jobs_dir/.src/panos/$scenes_dir)" ]; then
            # Build a temp file with every jpg file found
            # and sort it
            temp_array=$temp_folder/scenes_array
            temp_array_sort=$temp_folder/scenes_array_sort
            > $temp_array
            > $temp_array_sort
            for each_pano in $(find $jobs_dir/.src/panos/$(basename $scenes_dir)/ -maxdepth 1 -name "*.jpg"); do
                each_pano=$(basename "$each_pano")
                extension="${each_pano##*.}"
                each_pano="${each_pano%.*}"
                echo $each_pano >> $temp_array
            done
            sort --version-sort $temp_array >$temp_array_sort
            # Build an array containing all the scenes
            while read line; do
                scenes_array=( "${scenes_array[@]}" "$line")
            done < $temp_array_sort
        else
            echo_fail "There are no scenes.jpg in .src/panos/$scenes_dir"
            exit 1
        fi

        printf "    Contains ${#scenes_array[@]} scenes:\n" >> $log_file
        for eachitem in ${scenes_array[@]} ; do
            printf "    $eachitem\n" >> $log_file
        done

        # ADD ESTRUCTURE AND TILES
        rm_old_xml_files $scenes_dir
        add_structure
        add_scene_names
        #add_scene_tiles
        check_scene_tiles
        # include_plugin.temp
        add_include_plugin_and_data
        add_plugins_in_custom
        add_include_plugin
        # include_data.temp
        add_info_btn
        add_sa
        add_movecamera_coords
        add_logo_client
        add_hotspots
        add_scroll
        add_plugins_data
        # tour.xml
        add_tour
        # add_tour_clean
        set_crossdomain
        add_plugins_dir
        add_html
        add_html_in_custom
        add_timestamp
        add_version

    done

    # LAST BUT NOT LEAST
    remove_temp

    if [ -z $1 ]; then
        add_list
    fi

}


if [ $(uname -s) = "Linux" ]; then
    clear
fi

if [ -f $config ]; then
    conf_file_found
    start $1
else
    build_config_file
    start $1
fi

printf "\n EOF\n" >> $log_file
echo_done
exit 0