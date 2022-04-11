#!/bin/bash

path_root=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
path_chains=$path_root/chains
path_accounts=$path_root/accounts
path_genesis=$path_root/private
path_socket=$path_root/network.sock
path_passwords=$path_accounts/password.sec
path_ipc="~/Library/Ethereum/geth.ipc"

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
	geth --datadir $path_chains/$node_name init $path_genesis/$genesis;

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
	local node_folder="$1"
	passwd="$2"
	echo "";
	echo "Create new account:";
	echo " IMPORTANT! let pwd be \"$passwd\" not no make it harder it should be OR go open \"$path_passwords\" and write password you want IMPORTANT!"
	geth --datadir $(cat $path_socket|awk '{print $3}'|head -n 1) account new
	echo "$passwd" > $path_passwords
}

function start_node()
{
	local node="$1"
	local networkid="$2"
	local rpcport="$3"
	local port="$4"

	echo "";
	echo "Starting node..."

	geth \
		--networkid "$networkid" \
		--mine \
		--miner.threads 1 \
		--miner.noverify \
		--datadir "$path_chains/$node" \
		--nodiscover \
		--http \
		--http.port "$rpcport" \
		--http.corsdomain "*" \
		--http.api eth,web3,personal,net \
		--port "$port" \
		--nat "any" \
		--unlock 0 \
		--password "$path_passwords" \
		--allow-insecure-unlock \
		--ipcpath "$path_ipc"
}


: '
> ТОЧКА ВХОДА
	Реинициализаци проекта 
'
echo "SCRIPT WRITTEN FOR GETH 1.10.17-stable"
echo "Reinitializing testnet..."; # add prompt
clear_project_folder;
init_node node1 $GENESIS__DEFAULT;
init_node node2 $GENESIS__DEFAULT;
echo "Testnet reinitialized.";


nodes_info

store_nodes

# выбор ноды, создание аккаунта для ноды, запуск ноды
node_choose # fills $node_current

echo "current node is $node_current"
account_new $node_current "123qwe"
start_node $node_current 4966 8545 30303