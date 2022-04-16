#!/bin/bash

path_root="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
path_chains="$path_root/chains"
path_accounts="$path_root/accounts"
path_genesis="$path_root/private"
path_keystore="$path_root/keystore"
path_socket="$path_root/network.sock"
path_passwords="$path_accounts/password.sec"
path_ipc="~/Library/Ethereum/geth.ipc"
path_geth_bin="/usr/local/Cellar/ethereum/1.10.17/bin/geth"

node_current=null

GENESIS__DEFAULT=testnet.json
#GENESIS__DEFAULT=testnet.json

function store_nodes() {
	shopt -s dotglob;
	shopt -s nullglob;
	cd $path_chains;
	NODES=(*/)
}
function node_choose() {
	PS3="which dir do you want? ";
	
	echo "There are ${#NODES[@]} dirs in the current path";
	echo $PS3;
	select dir in "${NODES[@]}"; 
		do echo "you selected ${dir}"'!'; 
		node_current=${dir:0:$((${#dir} - 1))}
		break; 
	done
}


# pwd		| /testnet
# keys		| ./private
# chains 	| ./chains
# init		| geth --datadir ../chain init testnet.json

: '
	Удаление старых данных тестнета
'
function clear_project_folder()
{ 
	# хранилище данных
	rm -f $path_socket && touch $path_socket;
	# ноды тестнета
	rm -rf $path_chains;
	# пароли
	rm -rf $path_accounts && mkdir $path_accounts && touch $path_passwords
	# сессии нод
	screen -ls|grep "node"|cut -d. -f1|tr -d "\t"|xargs kill -9; screen -wipe;
	# поднятые инстансы 
	ps aux|grep "geth"|awk '{print $2}'|tr '\n\r' ' ' | xargs kill -9
}



: '
	Инициализация ноды по параметру
'
function init_node()
{
	echo ""
	local node_name="$1";
	local genesis="$2";

	echo "Initializing NODE:{$node_name} via $genesis genesis block.";
	geth --datadir $path_chains/$node_name --keystore $path_keystore init $path_genesis/$genesis;

	echo "$node_name $genesis $path_chains/$node_name" >> $path_socket
}

function nodes_count()
{
	echo $(awk 'END { print NR }' $path_socket)
}

function nodes_info_cat() { cat $path_socket; }

function nodes_info()
{
	echo ""
	echo "Nodes info::"
	echo " $(nodes_count) nodes initialized.";
	echo " Additional info about them:";
	nodes_info_cat;
	echo "::end";
}

# ^ в целом уже можно циклом идти по нодам и делать что хочешь ^

function node1() 
{
	cat $path_socket|awk '{print $3}'|head -n 1;
}

function account_new()
{
	local node="$1"
	local password="$2"
	echo "";
	echo "Creating new account:";
	echo "$password" > $path_passwords

	geth --datadir $(cat $path_socket|grep $node|awk '{print $3}'|head -n 1) account new --password $path_passwords 

	# geth --datadir $(cat $path_socket|awk '{print $3}'|head -n 1) \
	# 	--keystore $(cat $path_socket|awk '{print $4}'|head -n 1) \
	# 	account new --password $path_passwords 
	# geth --datadir $(cat $path_socket|awk '{print $3}'|head -n 1) account new # get first node OLD 
	
}

function start_node()
{
	local node="$1"
	local networkid="$2"
	local rpcport="$3"
	local port="$4"
	local datadir="$path_chains/$node"

	echo "";

	if [[ $node = "node1" ]] 
	then
		params='--networkid "'"$networkid"'" --miner.noverify --datadir "'"$datadir"'" --nodiscover --http --http.port "'"$rpcport"'" --http.api eth,web3,personal,net --port "'"$port"'" --nat "any" --unlock 0 --password "'"$path_passwords"'" --allow-insecure-unlock'
		# params='--networkid "'"$networkid"'" --mine --miner.threads 1 --miner.noverify --datadir "'"$datadir"'" --nodiscover --http --http.port "'"$rpcport"'" --http.api eth,web3,personal,net --port "'"$port"'" --nat "any" --unlock 0 --password "'"$path_passwords"'" --allow-insecure-unlock'
	else
		params='--networkid "'"$networkid"'" --datadir "'"$datadir"'" --nodiscover --http --http.port "'"$rpcport"'" --http.api eth,web3,personal,net --port "'"$port"'" --nat "any"'
	fi

	cmd="$path_geth_bin $params"
	
	echo "Command to be run: "
	screenCMD="screen -dmS $node bash -c '$cmd; bash'"
	echo "1  : $screenCMD"
	echo "2  : geth attach $datadir/geth.ipc"
	echo "2.1: geth --datadir $datadir dumpconfig"
	echo ""

	# $screenCMD
	echo "Node {$node}: started." # not always
	echo "Connect via [screen -x $node]"
}

function start_nodes()
{
	rpcport=8545
	port=30303

	# выбор ноды, создание аккаунта для ноды, запуск ноды
	for node in "${NODES[@]}"; 
	do
		echo ""
		node=${node:0:$((${#node} - 1))}
		echo "Node {$node}: bootstrappin..."; 
		
		account_new $node "123qwe";
		if [[ $node = "node1" ]]
		then
			account_new $node "123qwe";
			account_new $node "123qwe";
		fi

		start_node $node 4966 $rpcport $port;
		rpcport=$(($rpcport + 1));
		port=$(($port + 1));
		echo "Node {$node}: bootstrap finished!"; 
done

	
}

# Get nodeid from Node
function nodeid()
{
	local datadir="$1"
	# local datadir="$2"

}

function init () 
{
	echo ""
	echo "Reinitializing testnet..."; # TODO: add prompt

	clear_project_folder;
	init_node node1 $GENESIS__DEFAULT;
	init_node node2 $GENESIS__DEFAULT;
	echo "Testnet reinitialized.";
}

function helper__init__hasPackage ()
{
	local package="$1"
	packageMissing=$(which $package|grep not)
	if [[ $packageMissing != "" ]]
	then
		echo "Please install $package ($packageMissing)."
		exit 1
	fi
}



: '
	Инициализация скрипт-функций
'
greet()
{
	echo "SCRIPT WRITTEN FOR GETH 1.10.17-stable"
	echo "MacOS edition"
}
checkParams()
{
	if [[ $ui_cmd = "" ]]
	then
		die "Скрипт принимает команды на вход"
	fi
}
die ()
{
	echo "$1"
	exit 1
}






: ' ------------------------------------------------------------------------------------------------
> ТОЧКА ВХОДА
	Реинициализаци проекта 
'
greet

# # get command
# ui_cmd="$1"

# checkParams

# # do the trick
# while [[ 1 ]]
# do
# 	echo "1"
# 	die "death"
# done







# helper__init__hasPackage xterm
helper__init__hasPackage screen


# Check references
# - xterm
# - screen?


init

# nodes_info

store_nodes

start_nodes

screen -ls
# sleep 99
# screen -x node1
# # выбор ноды, создание аккаунта для ноды, запуск ноды
# node_choose # fills $node_current

# echo "current node is $node_current"
# account_new $node_current "123qwe"
# start_node $node_current 4966 8545 30303