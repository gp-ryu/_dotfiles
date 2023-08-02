#!/bin/bash
#set -o xtrace  -o pipefail -o errexit


Usages(){
    local CMMD=$1; shift
    case "$CMMD" in
        run)
    /bin/cat << EOF
About   :
    Run web-based programs and links it into public url.
    It can link running programs either on the LOGIN NODE or WORKING NODE to public url.
    Rstudio, Jupyter compatible. 

Usage   :
    webLinker.sh run [jupyter|rstudio] <arguemnts> [-c CPUs] [-m Memory] [-t Time] [-p Port]

Option
    -c, CPUs        4
    -m, Memory      16G
    -t, Time        4:00:00
    -p, Port        8080
EOF
        ;;
        hpc)
        ;;
        *) 
    /bin/cat << EOF
About   :
    Run web-based programs and links it into public url.
    It can link following programs either on the LOGIN NODE or WORKING NODE to public url.
    Rstudio, Jupyter compatible. 

Usage   :
    webLinker.sh <command> <arguemnts> [-c CPUs] [-m Memory] [-t Time] [-p Port]

Commands:
    config  sevice configuration for ngrok & jupyter lab
    run     run service
    hpc     run service on HPC(CONDOR, SLURM)    
EOF
        ;;
    esac
}

varGetopts(){
    while getopts "c:m:t:p:h"  opt
    do
        case $opt in
            c) export CPUS=$OPTARG;;
            m) export MEMS=$OPTARG;;
            t) export TIME=$OPTARG;;
            p) export PORT=$OPTARG;;
            h) Usages; return 1;;
        esac
    done
    exec
}

Config(){ ##  Ngrok Configuration
    
    if [ ! -f $HOME/.local/bin/micromamba ]; then
        PATH=$HOME/.local/bin:$PATH
        curl micro.mamba.pm/install.sh | bash
    fi

    micromamba shell init --shell=bash $HOME/micromamba
    export MAMBA_EXE="$HOME/.local/bin/micromamba"
    export MAMBA_ROOT_PREFIX="$HOME/micromamba"
    . $HOME/micromamba/etc/profile.d/micromamba.sh
    micromamba activate
    micromamba install -c conda-forge --yes mprocs 


    if ! which jupyter &> /dev/null; then
        echo 'Jupyter not found'; return 1;
    fi
    if [[ ! -f $HOME/.jupyter/jupyter_lab_config.py ]]
    then {
        jupyter lab --generate-config; echo 'c.ServerApp.allow_remote_access = True' >> $HOME/.jupyter/jupyter_lab_config.py
        echo -e "pasword for Jupyter"
        jupyter lab password
    } else {
        grep "c.ServerApp.allow_remote_access" $HOME/.jupyter/jupyter_lab_config.py
        echo -e "pasword for Jupyter"
        jupyter lab password
    }
    fi
    #  ngrok config
    /bin/cat << EOF

Visit "https://dashboard.ngrok.com/signup"
    1. Sign up
    2. get your Authtoken from "https://dashboard.ngrok.com/get-started/your-authtoken"
    3. get your own domain from "https://dashboard.ngrok.com/cloud-edge/domains"

EOF
    echo -ne "autotoken\t:"  ; read -e TOKEN
    echo -ne "domain\t\t:"    ; read -e DOMAIN
    if [[ ! -f $(which ngrok) ]]
    then {
        echo "ngrok installing...."
        if[[ ! $PATH =~ $HOME/bin ]] && (mkdir -p $HOME/bin; export PATH=$HOME/bin:$PATH)
        (wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz $HOME ; tar xvzf $HOME/ngrok-v3-stable-linux-amd64.tgz -C $HOME/bin) && (rm -rf $HOME/ngrok-v3-stable-linux-amd64.tgz; echo "ngrok installed in $HOME/bin")
    }
    fi
    ngrok config add-authtoken $TOKEN

    echo -ne "\nGoogle account\t:"  ; read -e ACCOUNT
    mkdir -p ~/.ngrok 2>/dev/null
    echo $ACCOUNT > $HOME/.ngrok.config
    echo $DOMAIN >> $HOME/.ngrok.config

    # mprocs install 
    conda install -c conda-forge mprocs

    # Rstudio-server config
    /bin/cat << EOF > ${HOME}/.rsession.sh
#!/bin/bash
USER=\$(whoami)
source /etc/profile

#Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

source \$HOME/.bashrc

#load conda env from file
CONDA_ENV=\$(cat /tmp/rstudio-server/\${USER}_current_env)
echo "## CONDA ENV is >>>"
echo \${CONDA_ENV}

conda activate \${CONDA_ENV}
export RETICULATE_PYTHON=\$CONDA_PREFIX/bin/python

/usr/lib/rstudio-server/bin/rsession \$@
EOF
chmod 775 $HOME/.rsession.sh

    /bin/cat << EOF > ${HOME}/.database.conf
# Directory in which the sqlite database will be written
directory=/tmp/rstudio-server/gryu_database
EOF
chmod 775 $HOME/.database.conf

}


Run(){
    local CMMD=$1; shift
    echo $@ $CMMD
    varGetopts $@

    case "$CMMD" in
        jupyter) 
            mprocs --names '**NOTICE**,top,jupyter,ngrok' \
                "echo -e 'Visit $(sed '2q;d' $HOME/.ngrok.config) \nor \nVisit https://dashboard.ngrok.com/tunnels/agents'" \
                "top" \
                "jupyter lab --port $PORT --port-retries 0 --no-browser" \
                "ngrok http --oauth google --oauth-allow-email $(sed '1q;d' $HOME/.ngrok.config) --domain $(sed '2q;d' $HOME/.ngrok.config) $PORT"
        ;;
        rstudio)
            CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
            USER=$(whoami)
            # set a user-specific secure cookie key
            COOKIE_KEY_PATH=/tmp/rstudio-server/${USER}_secure-cookie-key
            rm -f $COOKIE_KEY_PATH
            mkdir -p $(dirname $COOKIE_KEY_PATH)
            # Rserver >= version 1.3 requires the --auth-revocation-list-dir parameter
            if [ $(sed -n '/^1.3./p;q' /usr/lib/rstudio-server/VERSION) ] ;
            then
              REVOCATION_LIST_DIR=/tmp/rstudio-server/${USER}_revocation-list-dir
              mkdir -p $REVOCATION_LIST_DIR
              REVOCATION_LIST_PAR="--auth-revocation-list-dir=$REVOCATION_LIST_DIR"
            else
              REVOCATION_LIST_PAR=""
            fi
            python -c 'import uuid; print(uuid.uuid4())' > $COOKIE_KEY_PATH
            chmod 600 $COOKIE_KEY_PATH
            # store the currently activated conda environment in a file to be read by rsession.sh
            CONDA_ENV_PATH=/tmp/rstudio-server/${USER}_current_env
            rm -f $CONDA_ENV_PATH
            echo "## Current env is >>"
            echo $CONDA_PREFIX
            echo $CONDA_PREFIX > $CONDA_ENV_PATH
            export RETICULATE_PYTHON=$CONDA_PREFIX/bin/python
            # store the current path in database config
            sed -i "s,directory=.*,directory=\/tmp\/rstudio-server\/${USER}_database," $HOME/.database.conf

            mprocs --names '**NOTICE**,top,jupyter,ngrok' \
                "echo -e 'Visit $(sed '2q;d' $HOME/.ngrok.config) \nor \nVisit https://dashboard.ngrok.com/tunnels/agents'" \
                "top" \
                "/usr/lib/rstudio-server/bin/rserver --server-daemonize=0 \
                    --www-port=$PORT \
                    --secure-cookie-key-file=$COOKIE_KEY_PATH \
                    --server-pid-file=$CWD/rstudio-server.pid \
                    --server-data-dir=$CWD/rstudio-server \
                    --rsession-which-r=$(which R) \
                    --rsession-ld-library-path=$CONDA_PREFIX/lib \
                    --rsession-path=$HOME/.rsession.sh \
                    --server-user $USER \
                    --database-config-file $HOME/.database.conf \
                    $REVOCATION_LIST_PAR" \
                "ngrok http --oauth google --oauth-allow-email $(cat $HOME/.ngrok.config) $PORT"
        ;;
        *) Usages
        ;;
    esac
}

RunPrecheck(){
    if [[ $1 =~ "jupyter" || $1 =~ "rstudio" ]]; then shift; else echo -e "**** service required ****\n";return 1; fi
    varGetopts $@
    if [[ ! $PORT ]]; then
        echo -e "**** PORT NUMBER REQUIRED ****\n"; return 1;
    elif [[ $(lsof -i :$PORT | grep -i listen) ]]; then
        echo -e "**** PORT PREOCCUPIED, AVOID THESE PORTS ****\n";
        netstat -tuln | grep -i listen | grep -Eo ':[0-9]+' | sort | uniq; return 1;
    elif ! which jupyter &> /dev/null; then
        echo -e '**** Jupyter lab not found ****\n' ; return 1;
    elif ! which ngrok &> /dev/null; then
        echo -e '**** ngrok not found ****\n'; return 1;
    fi
}

HPCPrecheck(){
    if which condor_submit &>/dev/null; then
        HPC_SYSTEM="CONDOR"
    elif which srun &> /dev/null; then
        HPC_SYSTEM="SLURM"
    fi
}

condorRun() {
    condor_submit \
        -queue 1 \
        accounting_group=group_genome.bio \
        executable=mprocs \
        arguments="--names NOTICE,jupyter,ngrok 'echo visit https://dashboard.ngrok.com/tunnels/agents' 'jupyter lab --port $PORT --port-retries 0' 'ngrok http --oauth google --oauth-allow-email $(cat $HOME/.ngrok.config) $PORT'" \
        request_cpus=$CPUS \
        request_memory=$MEMS \
        getenv=True \
        allowed_job_duration=36000
}

HPC_queue(){
    case "$HPC_SYSTEM" in
        SLURM) srun -c $CPUS --mem $MEMS -A $GROUPS -p $BATCH --pty mprocs --names NOTICE,jupyter,ngrok "echo 'visit https://dashboard.ngrok.com/tunnels/agents'" "jupyter lab --port $PORT --port-retries 0" "ngrok http --oauth google --oauth-allow-email $(cat $HOME/.ngrok.config) $PORT"
        ;;
        CONDOR)
        ;;
        *) echo default
        ;;
    esac
}

main (){
    if [ $1 ]; then CMMD=$1; shift
    else Usages; return 1;
    fi

    case "$CMMD" in
        config) Config 
        ;;
        run) RunPrecheck $@ && Run $@ || Usages $CMMD
        ;;
        hpc) (RunPrecheck && HPCPrecheck) && HPC_queue || Usages $CMMD
        ;;
        *) Usages
        ;;
    esac
}
main "$@"



