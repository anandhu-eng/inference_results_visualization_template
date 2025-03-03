#!/bin/bash

if [ ! -e docs ]; then
    git clone https://github.com/GATEOverflow/inference_results_visualization_template.git docs
    test $? -eq 0 || exit $?
fi

python3 -m pip install -r docs/requirements.txt

if [ ! -e overrides ]; then
    cp -r docs/overrides overrides
    test $? -eq 0 || exit $?
fi

repo_owner=${INFERENCE_RESULTS_REPO_OWNER:-mlcommons}
repo_branch=${INFERENCE_RESULTS_REPO_BRANCH:-main}
repo_name=${INFERENCE_RESULTS_REPO_NAME:-inference_results_${INFERENCE_RESULTS_VERSION}}
repo_token=${INFERENCE_RESULTS_REPO_TOKEN:-""}
ver_num=$(cat dbversion)
let ver_num++

rm -f docs/javascripts/config.js

if [ ! -e docs/javascripts/config.js ]; then
    if [ -n "${INFERENCE_RESULTS_VERSION}" ]; then
         echo "const results_version=\"${INFERENCE_RESULTS_VERSION}\";" > docs/javascripts/config.js;
         echo "var repo_owner=\"${repo_owner}\";" >> docs/javascripts/config.js;
         echo "var repo_branch=\"${repo_branch}\";" >> docs/javascripts/config.js;
         echo "var repo_name=\"${repo_name}\";" >> docs/javascripts/config.js;
         echo "var repo_token=\"${repo_token}\";" >> docs/javascripts/config.js;
         echo "const dbVersion =\"${ver_num}\";" >> docs/javascripts/config.js;
         echo "const default_category =\"${default_category}\";" >> docs/javascripts/config.js;
         echo "const default_division =\"${default_division}\";" >> docs/javascripts/config.js;
    else
       echo "Please export INFERENCE_RESULTS_VERSION=v4.1 or the corresponding version";
       exit 1
    fi
fi

if [ ! -e docs/thirdparty/tablesorter ]; then
    cd docs/thirdparty && git clone https://github.com/Mottie/tablesorter.git && cd -
    test $? -eq 0 || exit $?
fi

if [ ! -e process_results_table.py ]; then
    cp docs/process_results_table.py .
    test $? -eq 0 || exit $?
fi

if [ ! -e process.py ]; then
    cp docs/process.py .
    test $? -eq 0 || exit $?
fi

if [ ! -e add_results_summary.py ]; then
    cp docs/add_results_summary.py .
    test $? -eq 0 || exit $?
fi

python3 process.py
test $? -eq 0 || exit $?
python3 process_results_table.py
test $? -eq 0 || exit $?

if [ ! -e inference ]; then
    git clone https://github.com/mlcommons/inference --depth=1
    test $? -eq 0 || exit $?
fi

python3 add_results_summary.py
test $? -eq 0 || exit $?
git push || (sleep $((RANDOM % 100 + 1)) && git pull --rebase && git push)

git config --global user.name "mlcommons-bot"
git config --global user.email "mlcommons-bot@users.noreply.github.com"

git add '**/README.md' '**/summary.html'
git commit -m "Added results summary"
git push
