#!/bin/bash

# Usage:
# 1- Execute this a first time from inside jobs/job_folder/
#    Inside this directory, put the panoramas in panos/virtual_tour_name/
# 2- Then go to g/virtual_tours/project_folder/ and edit vt_conf.sh to add/remove features
#    Once finished run the script again.
#
# Scroll options:
#    scroll=n              -> delete any folder named 'scroll', including any copied from .custom/
#    scroll=y              -> copies the 'scroll' folder from the template directory
#    scroll=k              -> neither copies or removes the 'scroll' folder
#    scroll_more=title     -> add scroll without title
#    scroll_more=notitle   -> idem as custom but without title

# Some paths variables
if ! [ $HOSTNAME = "RafaelGP" ]; then
    mydrive=/media/c/Users/rafaelgp/work
else
    mydrive=/media/g
fi
# origin directory paths
orig_dir=$mydrive/virtual_tours/.archives/bin/newvt/src
orig_content=$orig_dir/content
orig_include=$orig_dir/include
orig_structure=$orig_dir/structure
orig_devel=$orig_structure/files/devel.xml
# monitor script
config=./vt_conf.sh
krpano_version="1.16.2"
# temp
temp_folder=./.src/temp
include_plugin=$temp_folder/include_plugin
include_data=$temp_folder/include_date

echo_green() {
    echo -e "    \e[32m$1\e[0m    $2"
}
echo_warning() {
    echo -e "\e[41mWARNING:\e[0m $1"
}
echo_attention() {
    echo -e "    \e[93m> ATTENTION:   \e[0m $1"
}

conf_file_found () {
    if ! [ $HOSTNAME = "RafaelGP" ]; then
        # echo "is c"
       # Replace /media/g with /media/c
        sed -i 's/\/media\/g/\/media\/c\/Users\/rafaelgp\/work/g' $config
    else
        # echo "is g"
        # Replace /media/c with /media/g
        sed -i 's/\/media\/c\/Users\/rafaelgp\/work/\/media\/g/g' $config
    fi
    source $config
    if [ -z $timestamp ]; then
        echo_warning "timestamp variable not defined"
        exit 1
    elif [ -z $domain_url ]; then
        echo_warning "domain_url variable not defined"
        exit 1
    elif [ -z $list ]; then
        echo_warning "list variable not defined"
        exit 1
    else
        log_file=$new_dir/newvt.log
        > $log_file
        echo "vt_conf.sh file found" >> $log_file
        echo "FOUND:          vt_conf.sh ..."
    fi
}

build_config_file () {
    # Set folder paths for the input (jobs/) and the output (virtualtours/) directories
    # If it's a test use test directory as an output directory'
    echo "Is this a test? [y/n]"
    read testing
    if [ $testing = "n" ]; then
        read -e -p "Path to virtual tour output folder: " -i "$mydrive/virtual_tours/" VTPATH
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
    echo "vt_conf.sh file not found" >> $log_file

    # Define config var and create a dir.
    # $config will be difined again in add_structure to add a relative path to it
    > $config

     # Config file has three sections:

    # 1- Folder paths: input and output directories
    echo '#!/bin/bash'                      >> $config
    echo ''                                 >> $config
    echo "# ========== Paths =========="    >> $config
    echo "testing=$testing"                 >> $config
    echo "jobs_dir=$jobs_dir"               >> $config
    echo "new_dir=$new_dir"                 >> $config
    echo "domain_url=http://clients.tourvista.co.uk/vt/-----/files" >> $config
    echo ''                                 >> $config

    # 2- Base: plugins that are always inculded in a virtual tour
    base="coordfinder|editor_and_options|global|gyro|movecamera|sa|startup"
    echo "# ========== Base =========="     >> $config
    for d in $orig_include/*; do
    # for d in $orig_include/@($base); do
        plugin=$(basename $d)
        [[ ! $plugin =~ ^($base)$ ]] && continue
        echo "$plugin=y"                    >> $config
    done
    echo ''                                 >> $config

    # 3- Optional: There are 2 types.
    # echo "Basic features [1] No features [2]"

    # read features
    echo "# ========== Optional ==========" >> $config
    #    -Basic: with instructions and full screen button. Logo is included but not displayed
    # if [ $features = "1" ]; then
        # echo "fullscreen=y"                 >> $config
        # echo "instructions=y"               >> $config
        # echo "logo=n"                       >> $config
        # echo "logo_client=n"                >> $config
        # echo "Generated vt_conf.sh with basic features" >> $log_file
    # fi
    #    - No fuatures: all the values are set to 'n'
    # if [ $features = "2" ]; then
    for d in $orig_include/*; do
    # for d in $orig_include/!($base); do
        optional_plugins=$(basename $d)
        [[ $optional_plugins =~ ^($base)$ ]] && continue
        echo "$optional_plugins=n"                    >> $config
    done
    echo ''                                 >> $config
    echo "# ========== Options =========="  >> $config
    echo "timestamp=n"                   >> $config
    echo "list=y"                         >> $config

    echo "Generated vt_conf.sh without any features" >> $log_file
    # fi
    # Source vt_conf.sh, which doesn't have any features yet
    source $config

    echo "ADDED:          vt_conf.sh ..."
}

# -------------------
# STRUCTURE FUNCTIONS
# -------------------

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
        echo_warning "Copy files from template FAILED"
        exit 1
    fi

    echo -e "\n    COPY STRUCTURE TO $dest_dir\n" >> $log_file

    # devel.xml needs to be replaced always
    cp $orig_devel $dest_devel
    cat >> $log_file << EOF
    COPY FILE $orig_devel
    TO $dest_devel

EOF

    # source scene names for .sh files in root dir
    scenes_file=./$scenes_dir'.sh'
    if [ -f $scenes_file ]; then
        source $scenes_file
        echo -e "    Sourced $scenes_file\n" >> $log_file
    else
        echo_attention "Unable to source scene.sh file"
    fi

    echo_green "FOLDER TREE:" "added to $scenes_dir tour"
}

add_custom_dir() {

    # Create .custom/include directories if there is more than 1 scene (scenes, not pano images)
    # .custom contains custom plugins to be included in every scene
    if [ ${#tours_array[@]} -gt "1" ]; then
        if [ ! -d $new_dir/.custom ]; then
            echo -e "\nMake .custom directory" >> $log_file
            mkdir $new_dir/.custom
        else
            echo -e "\n.custom directory already exists" >> $log_file
        fi
        if [ ! -d $new_dir/.custom/include ]; then
            mkdir $new_dir/.custom/include
        fi
        # I used to call .custom/ just custom/. So if it exists change the name
        if [ -d $new_dir/custom ]; then
            mv $new_dir/custom $new_dir/.custom
        fi
    fi
}

add_temp() {
    mkdir -p ./.src
    mkdir -p $temp_folder
    > $temp_folder/plugins.temp
    > $temp_folder/tiles.temp
    echo -e "\nMake directory $temp_folder" >> $log_file
}

remove_temp() {
    rm -r $temp_folder
}

add_scene_names_files () {
    if [ ! -d $new_dir/$(basename $scenes_dir)'.sh' ]; then
        > $new_dir/$(basename $scenes_dir)'.sh'
    fi
    for scene in "${scenes_array[@]}"; do
        echo $scene="SceneName" >> $new_dir/$(basename $scenes_dir)'.sh'
    done
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
      />

EOF
        order=$(expr $order + 1)
        echo -e "    Added $panoname TO $temp_folder/scene_names.temp" >> $log_file
    done
}

add_scene_tiles() {

    krpath="$mydrive/documents/software/virtual_tours/krpano/krpanotools-$krpano_version/kmakemultires.exe"
    krconfig="C:\Users\rafaelgp\work\documents\software\virtual_tours\krpano\krpano_conf\templates\tv_tiles_2_levels_all_devices.config"
    # krconfig="-config=templates/tv_tiles_2_levels_all_devices.config"

    # If scenes directory doesn't exists, create it
    if [ ! -d $dest_scenes ]; then
        mkdir -p $dest_scenes
        echo -e "\nMake directory $dest_scenes" >> $log_file
    fi
    # Create tiles only if there isn't a folder in scenes/
    # with the same name as the scene#.jpg
    for panoimage in $(find $panos_dir/*.jpg -maxdepth 0 ); do
    # for panoimage in $panos_dir
    # Get rid off the path and the extension
        # echo "+++++++ $panoimage"
        filename=$(basename "$panoimage")
        extension="${filename##*.}"
        filename="${filename%.*}"
        if [ ! -d $dest_scenes/$filename ]; then
            cygwin_dir=$panoimage
            echo -e "\ncygwin_dir is $cygwin_dir" >> $log_file
            if [ $HOSTNAME = "RafaLaptop" ]; then
                # Replace /cygwin/c/ with C:/
                win_path=$(echo $cygwin_dir | sed -e 's/\/media\/c/C\:/g')
            else
                # Replace /cygwin/g/ with G:/
                win_path=$(echo $cygwin_dir | sed -e 's/\/media\/g/G\:/g')
            fi
            echo "win_path is $win_path" >> $log_file
            $krpath $krconfig $win_path

            if [ $? != 0 ]; then
                echo_warning  "Krpano tiles FILED while processing: $each_scene"
                exit 1
            else
                mv $panos_dir/output/scenes/$filename $dest_scenes
                mv $panos_dir/output/$filename.xml $dest_scenes
                sed -e 's/scenes/\%SWFPATH\%\/scenes/g' $dest_scenes/$filename.xml > $dest_scenes/bck_$filename.xml
                mv $dest_scenes/bck_$filename.xml $dest_scenes/$filename.xml
            fi
            echo -e "MADE TILES FOR: $(basename $scenes_dir)/$filename ..."
            echo -e "\nMove $panos_dir/output/scenes/$filename to $dest_scenes" >> $log_file
            echo "Move $panos_dir/output/$filename.xml to $dest_scenes" >> $log_file
        fi
    done

    # Replace '/scenes' for '%SWFPATH%/scenes' in all xml files in scenes in order to give it a valid path
    # for each_tiles_file in $(find $dest_scenes/*.xml -maxdepth 0 ); do
    # done

    # Delete output dirertory
    if [ -d $panos_dir/output ]; then
        rm -r $panos_dir/output
        echo -e "\nDelete directory  $panos_dir/output" >> $log_file
    fi

    for f in $(find $dest_scenes/*.xml -maxdepth 0 ); do
        cat $f >> $temp_folder/tiles.temp
    done
    echo -e "\nCreate File $temp_folder/tiles.temp" >> $log_file
}

# -------------------
# devel.xml FUNCTIONS FOR PLUGINS
# -------------------

# Every function embeds an <include /> in include_plugin.temp
# At the end it will host all the <include /> for the added plugins
# devel.xml will have that file enbeded replacing [PLUGINS]

add_include_plugin_and_data() {
    > $include_plugin
    > $include_data
    echo -e "\nCreate File $include_plugin" >> $log_file
    echo "Create File $include_data" >> $log_file
    # for D in $orig_include/*; do
    for D in $(find $orig_include/* -maxdepth 0 -type d ); do
        plugin=$(basename $D)
        plugin_value=${!plugin}
        # echo $plugin : $plugin_value
        if [ "$plugin_value" = "y" ]; then
            # echo '  <include url="%SWFPATH%/include/'$plugin'/index.xml" />' >> $include_plugin
            cp -r $orig_include/$plugin $dest_include
            echo -e "\n    Copy $orig_include/$plugin to $dest_include" >> $log_file
            # echo yes
        fi
        if [ "$plugin_value" = "n" ]; then
            if [ -d $dest_include/$plugin ]; then
                # sed -e '/$plugin/d' $temp_folder/devel5.temp > $temp_folder/devel6.temp
                # mv $temp_folder/devel6.temp $temp_folder/devel5.temp
                # echo -e "\nMove $temp_folder/devel6.temp to $temp_folder/devel5.temp" >> $log_file
                rm -rf $dest_include/$plugin
                echo -e "\nDelete $dest_include/$plugin" >> $log_file
                # echo no
            fi
        fi
        if [ "$plugin_value" = "k" ]; then
            # echo '  <include url="%SWFPATH%/'$plugin'/index.xml" />' >> $include_plugin
            echo -e "\n    $dest_include/$plugin NOT MODIFIED" >> $log_file
            # echo k
        fi
    done
    # Also include any folder manually added to the include/ directory
    # Will be duplicates, but they well be removed in 'add_include_plugin' function
    for dir_added in $(find $dest_include/* -maxdepth 0 -type d); do
        # echo $dir_added
        added_plugin=$(basename $dir_added)
        added_plugin_value=${!added_plugin}
        echo '  <include url="%SWFPATH%/include/'$added_plugin'/index.xml" />' >> $include_plugin
        echo -e "\n    $dest_include/$added_plugin KEEPED" >> $log_file
    done
    # exit 1
}

add_logo() {

    # if [ $logo = "y" ]; then
        # echo '  <include url="%SWFPATH%/include/logo/index.xml" />' >> $include_plugin;
        # cp -r $orig_include/logo $dest_include;
    # fi

    if [ $logo_client = "y" ]; then
        # echo '  <include url="%SWFPATH%/include/logo_client/index.xml" />' >> $include_plugin;
        # cp -r $orig_include/logo_client $dest_include;

        # echo "Choose the client logo:"
        # echo "Creare [1] Addoctor [2] Llama Digital [3] Other[4]"
        # read logo_client_name
        if [ $logo_client_name = "1" ]; then
            sed -i "s/CLIENTNAME/creare/g" $dest_include"/logo_client/index.xml"
        fi
        if [ $logo_client_name = "2" ]; then
            sed -i "s/CLIENTNAME/addoctor/g" $dest_include"/logo_client/index.xml"
        fi
        if [ $logo_client_name = "3" ]; then
            sed -i "s/CLIENTNAME/llama/g" $dest_include"/logo_client/index.xml"
        fi
        if [ $logo_client_name = "4" ]; then
            sed -i "s/CLIENTNAME/other/g" $dest_include"/logo_client/index.xml"
        fi
        # echo -e "\n Added LOGO CLIENT"
    fi
}

add_hotspot() {

    if [ $hotspots = "y" ]; then
        if [ ${#scenes_array[@]} -gt "1" ]; then
            if [ ! -f $dest_content/hs.xml ]; then
                > $dest_content/hs.xml
                echo '<krpano>'  >> $dest_content/hs.xml
                order=1
                for f in $(find $dest_scenes/*.xml -maxdepth 0); do
                    hs_action=add_hs_scene$order
                    scene_no=scene$order

                    echo '<action name="'$hs_action'">
    hs(up, '$scene_no', get(layer[swfaddress].pano['$scene_no'].title),0,0,0,0);
</action>
' >> $dest_content/hs.xml

                    order=$(expr $order + 1)
                done
                echo "</krpano>"  >> $dest_content/hs.xml
            fi
        else
            if [ -f $dest_content/hs.xml ]; then
                rm $dest_content/hs.xml
            fi
            if [ -d $dest_include/hotspots ]; then
                rm -r $dest_include/hotspots
                sed -i -e '/hotspots\/index.xml/d' $dest_devel
            fi
        fi
    fi
}

add_info_btn() {

    if [ $info_btn = "y" ]; then
        # echo '  <include url="%SWFPATH%/include/info_btn/index.xml" />' >> $include_plugin
        # cp -r $orig_include/info_btn $dest_include
        # Add a set_sidebar_scene action per scene to content/info_btn.xml
        # Never overwrite content/info_btn.xml!!!
        if [ ! -f $dest_content/info_btn.xml ]; then
            order=1
            > $dest_content/info_btn.xml
            for f in $(find $dest_scenes/*.xml -maxdepth 0); do
                actionname=set_sidebar_scene$order

                echo '<action name="'$actionname'">
    set(layer[sidebar_text].html,data:text1);
    set(sidebar_btn, true);
</action>
' >> $dest_content/info_btn.xml

                order=$(expr $order + 1)
            done
        fi
        # Add some data with text per scene to content/info_btn_text.xml
        if [ ! -f $dest_content/info_btn_text.xml ]; then
            order=1
            for f in $(find $dest_scenes/*.xml -maxdepth 0); do
                textname=text$order
                texttitle="Scene $order text"

                echo '<data name="'$textname'">
    <h2>'$texttitle'</h2><br/>
    <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>
</data>
' >> $dest_content/info_btn_text.xml

                order=$(expr $order + 1)
            done
        fi
    fi
}

# Replace the line containing [PLUGINS] with temp/include_plugin_sort.temp
add_include_plugin() {
    # Remove duplicated lines
    include_plugin_sort=$temp_folder/include_plugin_sort.temp
    sort -u $include_plugin > $include_plugin_sort
    # cp $include_plugin_sort $include_plugin
    sed -i -e "/\[PLUGINS\]/r $include_plugin_sort" $dest_devel
    sed -i -e '/\[PLUGINS\]/d' $dest_devel
    echo "ADDED:          plugins ..."
    echo -e "\n---> Added $include_plugin to $dest_devel" >> $log_file
}

# -------------------
# devel.xml FUNCTIONS FOR DATA
# -------------------

# Every function adds an <include /> line in the file include_data.temp
# At the end it will host all the <include /> for the added data
# devel.xml will have that file enbedede substituting [DATA]

add_sa() {

    # overwrite content/sa.xml!!!
    # if [ ! -f $dest_content/sa.xml ]; then
        # Replace the line containing [SCENE_NAMES] with the scene names in temp/scene_names.temp
    cp -r $orig_content/sa.xml $dest_content/sa.xml
    sed -i -e "/\[SCENE_NAMES\]/r $temp_folder/scene_names.temp" $dest_content/sa.xml
    sed -i -e '/\[SCENE_NAMES\]/d' $dest_content/sa.xml
    echo -e "\n++++ Copied $orig_content/sa.xml to $dest_content/sa.xml" >> $log_file
    # fi
}

add_movecamera_coords()  {
    # Never overwrite content/coord.xml!!!
    if [ ! -f $dest_content/coord.xml ]; then
        order=1
        > $dest_content/coord.xml
        echo '<krpano>'  >> $dest_content/coord.xml
        echo -e "\nCreated $dest_content/coord.xml" >> $log_file
        # for f in $(find $dest_scenes/*.xml -maxdepth 0); do
        for eachpano in $(find $panos_dir/*.jpg -maxdepth 0 ); do
            # Get rid off the path and the extension
            eachpano=$(basename "$eachpano")
            extension="${eachpano##*.}"
            eachpano="${eachpano%.*}"

            # actionname=movecamera_scene$order
            # echo '<action name="'$actionname'">

            echo '<action name="movecamera_'$eachpano'">
    movecamera(0,0);
</action>
' >> $dest_content/coord.xml
            order=$(expr $order + 1)
            echo "Added $actionname to $dest_content/coord.xml" >> $log_file
        done
        echo "</krpano>"  >> $dest_content/coord.xml
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
}

add_scroll () {
    number_of_scenes=${#scenes_array[@]}
    echo "SCENES:         $number_of_scenes"

    if [ "$scroll" != "n" ]; then
        if [ "$scroll_more" = "title" ]; then
            scroll_swf='scroll_'$number_of_scenes'_title'
        fi
        if [ "$scroll_more" = "notitle" ]; then
            scroll_swf='scroll_'$number_of_scenes
        fi
        if [ ${#scenes_array[@]} -gt "1" ]; then
            add_scroll_data
        else
            remove_scroll
        fi
    fi
}

add_scroll_data() {
    # if [ "$scroll" = "y" ]; then

        # count number of xml files in scenes directory
    # if [ "$scroll" = "y" ]; then
        # scroll_swf='scroll_'$number_of_scenes'_title'
    # fi
    # if [ "$scroll" = "custom" ]; then
        # scroll_swf='scroll_'$number_of_scenes'_title'
    # fi
    # if [ "$scroll" = "notitle" ]; then
        # scroll_swf='scroll_'$number_of_scenes
    # fi
    # if [ "$scroll" = "custom_notitle" ]; then
        # scroll_swf='scroll_'$number_of_scenes
    # fi

        # Replace the word [SWF_FILE] with the swf file name, in include/scroll/index.xml
    sed -i "s/\[SWF_FILE\]/$scroll_swf/g" $dest_include'/scroll/index.xml'
        # Copy the corresponding swf file for the number of scenes
    cp -r $orig_content'/scroll/'$scroll_swf.swf  $dest_include'/scroll'

        # Make content/scroll_thumbs/ directory if doesn't exists
    if [ ! -d $dest_content'/scroll_thumbs' ]; then
        mkdir $dest_content'/scroll_thumbs'
    fi

        # Create content/scroll.xml
        # if [ ! -f $dest_content/scroll.xml ]; then
    > $dest_content/scroll.xml
    order=1
    echo '<content>' >> $dest_content/scroll.xml
    for file_name in ${scenes_array[@]}; do
            # file_name=scene$order
                # scene_name="Scene $order"
        echo '<item>
    <path>files/content/scroll_thumbs/'$file_name'.jpg</path>
    <foldername>'$file_name'</foldername>
    <data>'${!file_name}'</data>
    <type>image</type>
    <order>'$order'</order>
</item>
' >> $dest_content/scroll.xml

       # Make a thumbnail for each pano, only if it doesn't exists already
        if [ ! -f $dest_content'/scroll_thumbs/'$file_name'.jpg' ]; then
            convert $panos_dir/$file_name'.jpg' -resize 420x210^ -gravity center -extent 200x120 $dest_content'/scroll_thumbs/'$file_name'.jpg'
        fi

        order=$(expr $order + 1)
    done
    echo '</content>' >> $dest_content/scroll.xml
        # fi

    # fi

}
add_plugins_data() {
    for f in $dest_content/*.xml; do
        # Get rid off the path and the extension
        file_name=$(basename "$f")
        extension="${file_name##*.}"
        file_name="${file_name%.*}"

        echo '  <include url="%SWFPATH%/content/'$file_name'.xml" />' >> $include_data
    done

    # Replace the line containing [DATA] with content
    sed -i -e "/\[DATA\]/r $include_data" $dest_devel
    sed -i -e '/\[DATA\]/d' $dest_devel
    echo -e "\n**** Added $include_data to $dest_devel" >> $log_file

    # Replace the line containing [TILES] with content in temp/each_tiles_files.temp
    # I haven't created tiles.xml because that would add <include url="scenes/scene1.xml" />
    # and then the tiles path would be relative to devel.xml and it'd be
    # a wrong path (/files/scenes/scenes/scene1/...)
    > $temp_folder/all_tiles_files.temp
    for each_tiles_file in $(find $dest_scenes/*.xml -maxdepth 0 ); do
        echo '  <include url="%SWFPATH%/scenes/'$(basename $each_tiles_file)'" />' >> $temp_folder/all_tiles_files.temp
    done
    sed -i -e "/\[TILES\]/r $temp_folder/all_tiles_files.temp" $dest_devel
    sed -i -e '/\[TILES\]/d' $dest_devel

    echo "ADDED:          data ..."
    echo -e "\nAdded $temp_folder/tiles.temp to $dest_devel" >> $log_file
}

# -------------------
# tour.xml FUNCTIONS
# -------------------

# tour.xml is made stripping out devel.xml
# Extract the urls form devel.xml, discarting the lines containing 'scenes''
# Embed the files corresponding to each url
# Embed tiles code form temp/tiles.temp
# Delete any krpano tags
# Then add krpano tags one at the top and one at the bottom

add_tour() {

    tour_file=$dest_files/$1.xml
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
        # cat $dest_files"/"$line >> $tour_file
        cat $dest_files$line >> $tour_file
        # echo $dest_files$line
        # echo $line
    done < $temp_folder"/devel5.temp"
# exit 1

    # Add tiles code
    > $temp_folder/tiles.temp
    for f in $(find $dest_scenes -type f -name \*.xml); do
        cat $f >> $temp_folder/tiles.temp
    done
    cat $temp_folder/tiles.temp >> $tour_file

    # Delete all the lines beginning with <?xml, <krpano </krpano
    sed -i '/^<?xml/d' $tour_file
    sed -i '/^<krpano/d' $tour_file
    sed -i '/^<\/krpano/d' $tour_file

    # Add krpano tags at the beginning of tour.xml
    # If it's tour_clean.xml,then add an onstart action to load scene1'
    if [ $1 = "tour_clean" ]; then
        sed -i "1i<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<krpano version=\"$krpano_version\" showerrors=\"false\" onstart=\"activatepano(scene1);\">" $tour_file
    else
        sed -i "1i<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<krpano version=\"$krpano_version\" showerrors=\"false\">" $tour_file
    fi
    # Add closing krpano tag at the end of tour.xml and tour_clean.xml
    echo '</krpano>' >> $tour_file

    # Delete empty lines
    sed -i '/^$/d' $tour_file

    # Delete commented lines
    sed -i '/-->/d' $tour_file

    # if [ -f "$krpano2" ]; then
        # echo "ADDED:          krpano2.xml ..."
    # else
    # file_generated=tour.xml
    echo "ADDED:          $1 ..."
    # file_generated=krpano2.xml
    # fi
    if [ -f $dest_content/sa_bck.xml ]; then
    # If there is a sa_bck.xml file then:
    # Restore sa.xml with swfaddress plugin, so the next time I run the script
    # tour.xml will have swfaddress plugin included.
    # Otherwise tour.xml would always include the deleted swfaddress plugin version
        mv $dest_content/sa_bck.xml $dest_content/sa.xml
    fi

}

add_tour_clean() {
    # Duplicate tour.xml and rename it as tour2.xml
    # cp $krpano $krpano2
    # Make a backup of sa.xml containing the swfaddress plugin
    mv $dest_content/sa.xml $dest_content/sa_bck.xml
    # Delete content/sa.xml and create a new one without the swf address plugin
    > $dest_content/sa.xml
    echo '<layer name="swfaddress" keep="true">' >> $dest_content/sa.xml
    cat $temp_folder/scene_names.temp >> $dest_content/sa.xml
    echo '</layer>' >> $dest_content/sa.xml
    # then build tour.xml again, this time without sa.swf, and call it tour_clean.xml
    add_tour "tour_clean"
    # Source config again so domain_url can get $scenes_dir value
    source $config
    # Replace %SWFPATH% with the value of $domain_url
    sed -i "s|\%SWFPATH\%|$domain_url|g" $dest_files/tour_clean.xml
}

add_html() {
    for item in "${scenes_array[@]}"; do
    # echo "$item.html = $item"
        cp -r $orig_content/scene.html $dest_dir/$item.html
        sed -i "s/SCENENAME/$item/g" $dest_dir/$item.html
        sed -i "s|files|$domain_url|g" $dest_dir/$item.html
        echo -e "\nMade $item.html file" >> $log_file
    done
    echo "ADDED:          html files ..."
}

add_custom() {
    if [ -d $new_dir/.custom ]; then
        if [ "$(ls -A $new_dir/.custom/include)" ]; then
            for eachdirectory in $(find $new_dir/.custom/include/* -maxdepth 0 -type d ); do
                cp -r $eachdirectory $dest_include
                echo '  <include url="%SWFPATH%/include/'$(basename $eachdirectory)'/index.xml" />' >> $include_plugin;
                echo -e "\nADDED $(basename $eachdirectory) from .custom/include/" >> $log_file
            done
        else
            echo -e "\n.custom/include is empty" >> $log_file
        fi
    fi

    echo "ADDED:          custom plugins ..."
}

add_timestamp() {
    if [ $timestamp = "y" ]; then
        timestamp=$(date "+%Y%m%d%H%M%S").xml
        for each_tour_xml in $(find . -name tour.xml); do
        # Get rid off the extension
            extension="${each_tour_xml##*.}"
            each_tour_xml="${each_tour_xml%.*}"
            mv  $each_tour_xml.xml $each_tour_xml$timestamp
        # echo "$each_tour_xml.xml -> $each_tour_xml$timestamp"
        done
        for each_tour_clean_xml in $(find . -name tour_clean.xml); do
        # Get rid off the extension
            extension="${each_tour_clean_xml##*.}"
            each_tour_clean_xml="${each_tour_clean_xml%.*}"
            mv  $each_tour_clean_xml.xml $each_tour_clean_xml$timestamp
        # echo "$each_tour_clean_xml.xml -> $each_tour_clean_xml$timestamp"
        done
        for each_html_file in $(find . -name "*.html"); do
            sed -i "s/tour_clean.xml/tour_clean$timestamp/g" $each_html_file
            sed -i "s/tour.xml/tour$timestamp/g" $each_html_file
        done
    fi
}

add_version() {
    for each_xml_file in $(find $scenes_dir/files/ -type f  -name "*.xml"); do
        sed -i "s/<krpano>/<krpano version=\"$krpano_version\">/g" $each_xml_file
    done
    echo "ADDED:          version $krpano_version  ..."
}

add_list() {
    if [ $list = "y" ]; then

        index_file="./index.html"
        src="./.src/generate_html"
        temp_dir="$src/temp"
        template_file="$src/template.html"
        content_file="$temp_dir/content"

        # Get the template
        cp -r $orig_dir/generate_html/template.html $src
        # Download style.css from tourvista
        if [ ! -f "./style.css" ]; then
            wget http://www.tourvista.co.uk/css/style.css
        fi

        cp $template_file $index_file
        mkdir -p $temp_dir
        > $content_file

        for tour in .src/panos/*; do
            tour_name="$(basename $tour)"
            echo $tour_name
            tour_title="${tour_name//_/ }"
            all_brands_array=( $tour_title )
            tour_title="${all_brands_array[@]^}"
            temp_file="$temp_dir/tour_$tour_name"
            > $temp_file
            echo "<h4><a href="$tour_name/index.html">$tour_title</a></h4>" >> $temp_file
            echo "<ul>" >> $temp_file
            for scene_html in ./.src/panos/$tour_name/*; do
                scene_name="$(basename $scene_html)"
                extension="${scene_name##*.}"
                scene_name="${scene_name%.*}"
                echo "    $scene_name"
                scene_fancy_name="${scene_name//_/ }"
                all_words_array=( $scene_fancy_name )
                scene_fancy_name="${all_words_array[@]^}"
                echo "<li><a href=\"$tour_name/$scene_name.html\">$scene_fancy_name</a></li>" >> $temp_file
            done
            echo "</ul>" >> $temp_file

            cat $temp_dir/tour_$tour_name >> $content_file

            cp $template_file ./$tour_name/index.html

            sed -i "s/$tour_name\///g" "$temp_dir/tour_$tour_name"
            sed -i -e "/\[CONTENT\]/r $temp_dir/tour_$tour_name" ./$tour_name/index.html
            sed -i -e '/\[CONTENT\]/d' ./$tour_name/index.html
            sed -i -e 's/<h4><a href=index.html>/<h4>/g' ./$tour_name/index.html
            sed -i -e 's/<\/a><\/h4>/<\/h4>/g' ./$tour_name/index.html
            sed -i -e 's/.\/style.css/..\/style.css/g' ./$tour_name/index.html
        done

        sed -i -e "/\[CONTENT\]/r $content_file" $index_file
        sed -i -e '/\[CONTENT\]/d' $index_file

        rm -r $temp_dir
    fi
}

rm_old_xml_files() {
    if [ -d "$scenes_dir" ]; then
        if [ ! -z $1 ]; then
            find $1 -maxdepth 1 -type f -name "*.html" -exec rm -rf {} \;
            # Remove any xml file which date stamp is year 2000 onwards
            find $1 -name "tour20*.xml" -exec rm -rf {} \;
            find $1 -name "tour_clean20*.xml" -exec rm -rf {} \;
        else
            echo_attention "rm_old_xml_files() -> \$1 not defined"
            echo $1
        fi
    else
        echo_warning "rm_old_xml_files() -> $scenes_dir folder doesn't exist"
    fi
}

start () {
    add_temp
    mkdir -p $temp_folder
    echo -e "\norig_dir is: $orig_dir" >> $log_file
    echo "new_dir is: $new_dir" >> $log_file
    echo "jobs_dir is: $jobs_dir" >> $log_file

    tours_array=()
    # To run the script for a particular tour, enter its folder name as a param
    # Any trailing back slash at the end is automatically removed
    if [ ! -z $1 ]; then
        declare -a tours_array=( ${1%/})
    else
        for each_tour in $(find $jobs_dir/.src/panos/* -maxdepth 0 -type d ); do
            each_tour=$(basename "$each_tour")
            tours_array=( "${tours_array[@]}" "$each_tour")
        done
    fi

    # Let me khow how many tours are in total
    if [ ${#tours_array[@]} = 1 ]; then
        echo -e "\nThere is only ${#tours_array[@]} tour: ${tours_array[@]}" >> $log_file
    else
        echo -e "\nThere are ${#tours_array[@]} tours:" >> $log_file
        for eachitem in ${tours_array[@]} ; do
            echo -e "    $eachitem" >> $log_file
        done
    fi

    for scenes_dir in "${tours_array[@]}"; do
        echo "TOUR NAME: $scenes_dir"
        echo -e "\n---------------------------------" >> $log_file
        echo -e "TOUR: $scenes_dir" >> $log_file
        echo -e "---------------------------------\n" >> $log_file

        scenes_array=()
        for each_pano in $(find $jobs_dir/.src/panos/$(basename $scenes_dir)/*  -maxdepth 0 -name "*.jpg"); do
            each_pano=$(basename "$each_pano")
            extension="${each_pano##*.}"
            each_pano="${each_pano%.*}"
            scenes_array=( "${scenes_array[@]}" "$each_pano")
        done

        echo -e "    Contains ${#scenes_array[@]} scenes:" >> $log_file
        for eachitem in ${scenes_array[@]} ; do
            echo -e "    $eachitem" >> $log_file
        done

        rm_old_xml_files $scenes_dir
        add_structure
        add_scene_names
        add_scene_tiles
        add_include_plugin_and_data
        add_info_btn

        add_include_plugin
        add_custom
        add_sa
        add_movecamera_coords
        add_logo
        add_hotspot
        add_scroll
        add_plugins_data
        add_tour "tour"
        add_tour_clean
        add_html
        add_timestamp
        add_version

        # LAST BUT NOT LEAST
        remove_temp
    done

    if [ -z $1 ]; then
        add_list
    fi

    add_custom_dir
    # NEED TO MAKE THIS WORK
    # add_scene_names_files

}

if [ -f $config ]; then
    conf_file_found
    start $1
else
    build_config_file
    start $1
fi

echo -e "\nEOF" >> $log_file
echo "EOF"
exit 0