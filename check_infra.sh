#!/bin/bash
file_directory=`pwd`
file_name=`ls|tail -1`
cd $HOME/my_analysis/ocp_insights_sh/
./ocp_insights.sh --file $file_directory/$file_name
