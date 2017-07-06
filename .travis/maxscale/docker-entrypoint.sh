#!/bin/bash

set -e

config_file="/etc/maxscale.cnf"

# We start config file creation

cat <<EOF > $config_file
#
# Global parameters
#
# Number of worker threads in MaxScale
#
# 	threads=<number of threads>
#
# Enabled logfiles. The message log is enabled by default and
# the error log is always enabled.
#
# log_messages=<1|0>
# log_trace=<1|0>
# log_debug=<1|0>
## Example:

[maxscale]
threads=2


[db]
type=server
address=db
port=3306
protocol=MySQLBackend
authenticator_options=skip_authentication=true
router_options=master

## Define a monitor that can be used to determine the state and role of
# the servers.
#
# Currently valid options for all monitors are:
#
# 	module=[mysqlmon|galeramon]
#
# List of server names which are being monitored
#
# 	servers=<server name 1>,<server name 2>,...,<server name N>
#
# Username for monitor queries, need slave replication and slave client privileges
# Password in plain text format, and monitor's sampling interval in milliseconds.
#
#	user=<username>
# 	passwd=<plain txt password>
#	monitor_interval=<sampling interval in milliseconds> (default 10000)
#
# Timeouts for monitor operations in backend servers - optional.
#
#	backend_connect_timeout=<timeout in seconds>
#	backend_write_timeout=<timeout in seconds>
#	backend_read_timeout=<timeout in seconds>
#
## MySQL monitor-specific options:
#
# Enable detection of replication slaves lag via replication_heartbeat
# table - optional.
#
# 	detect_replication_lag=[1|0] (default 0)
#
# Allow previous master to be available even in case of stopped or misconfigured
# replication - optional.
#
# 	detect_stale_master=[1|0] (default 0)
#
## Galera monitor-specific options:
#
# If disable_master_failback is not set, recovery of previously failed master
# causes mastership to be switched back to it. Enabling the option prevents it.
#
#	disable_master_failback=[0|1] (default 0)
#
## Examples:

#[MySQL Monitor]
#type=monitor
#module=mysqlmon
#servers=server1,server2,server3
#user=myuser
#passwd=mypwd
#monitor_interval=10000
#backend_connect_timeout=
#backend_read_timeout=
#backend_write_timeout=
#detect_replication_lag=
#detect_stale_master=

[Galera Monitor]
type=monitor
module=mysqlmon
servers=db
user=boby
passwd=hey
monitor_interval=1000
#disable_master_failback=

## Filter definition
#
# Type specifies the section
#
#	type=filter
#
# Module specifies which module implements the filter function
#
#	module=[qlafilter|regexfilter|topfilter|teefilter]
#
# Options specify the log file for Query Log Filter
#
#	options=<path to logfile>
#
# Match and replace are used in regexfilter
#
#	match=fetch
#	replace=select
#
# Count and filebase are used with topfilter to specify how many top queries are
# listed and where.
#
#	count=<count>
#	filebase=<path to output file>
#
# Match and service are used by tee filter to specify what queries should be
# duplicated and where the copy should be routed.
#
#	match=insert.*HighScore.*values
#	service=Cassandra
#
## Examples:

[qla]
type=filter
module=qlafilter
options=/tmp/QueryLog

[fetch]
type=filter
module=regexfilter
match=fetch
replace=select

[hint]
type=filter
module=hintfilter


## A series of service definition
#
# Name of router module, currently valid options are
#
# 	router=[readconnroute|readwritesplit|debugcli|CLI]
#
# List of server names for use of service - mandatory for readconnroute,
# readwritesplit, and debugcli
#
# 	servers=<server name 1>,<server name 2>,...,<server name N>
#
# Username to fetch password information with and password in plaintext
# format - for readconnroute and readwritesplit
#
# 	user=<username>
# 	passwd=<password in plain text format>
#
# flag for enabling the use of root user - for readconnroute and
# readwritesplite - optional.
#
#	enable_root_user=[0|1] (default 0)
#
# Version string to be used in server handshake. Default value is that of
# MariaDB embedded library's - for readconnroute and readwritesplite - optional.
#
#	version_string=<specific version string>
#
# Filters specify the filters through which the query is transferred and the
# order of their appearance on the list corresponds the order they are
# used. Values refer to names of filters configured in this file - for
# readconnroute and readwritesplit - optional.
#
#	filters=<filter name1|filter name2|...|filter nameN>
#
## Read Connection Router specific router options.
#
# router_options specify the role in which the selected server must be.
#
#	router_options=[master|slave|synced]
#
## Read/Write Split Router specific options.
#
# use_sql_variables_in specifies where sql variable modifications are
# routed - optional.
#
#	use_sql_variables_in=[master|all] (default all)
#
# router_options=slave_selection_criteria specifies the selection criteria for
# slaves both in new session creation and when route target is selected - optional.
#
#	router_options=
#	slave_selection_criteria=[LEAST_CURRENT_OPERATIONS|LEAST_BEHIND_MASTER]
#
# router_options=max_sescmd_history specifies a limit on the number of 'session commands'
# a single session can execute. Please refer to the configuration guide for more details - optional.
#
#	router_options=
#	max_sescmd_history=2500
#
# max_slave_connections specifies how many slaves a router session can
# connect to - optional.
#
#       max_slave_connections=<number, or percentage, of all slaves>
#
# max_slave_replication_lag specifies how much a slave is allowed to be behind
# the master and still become chosen routing target - optional, requires that
# monitor has detect_replication_lag=1 .
#
#       max_slave_replication_lag=<allowed lag in seconds for a slave>
#
# Valid router modules currently are:
# 	readwritesplit, readconnroute, debugcli and CLI
#
## Examples:

[Write Connection Router]
type=service
router=readconnroute
servers=db
user=boby
passwd=hey
router_options=master
localhost_match_wildcard_host=1
version_string=10.2.99-MariaDB-maxscale

[Read Connection Router]
type=service
router=readconnroute
servers=db
user=boby
passwd=hey
router_options=synced
localhost_match_wildcard_host=1
version_string=10.2.99-MariaDB-maxscale

[RW Split Router]
type=service
router=readwritesplit
servers=db
user=boby
passwd=hey
max_slave_connections=100%
localhost_match_wildcard_host=1
router_options=disable_sescmd_history=true
version_string=10.2.99-MariaDB-maxscale

#use_sql_variables_in=master
#max_slave_replication_lag=21
#filters=hint|fetch|qla
#router_options=slave_selection_criteria=LEAST_CURRENT_OPERATIONS

# Uncomment this to disable the saving of session modifying comments. Some scripting
# languages use connection pooling and will use the same session. MaxScale sees them
# as the same session and stores them for the slave recovery process.
#router_options=disable_sescmd_history=true,disable_slave_recovery=true

# This will allow the master server to be used for read queries. By default
# MaxScale will only use the master for write queries.
#router_options=master_accept_reads=true

[CLI]
type=service
router=cli

## Listener definitions for the services
#
# Type specifies section as listener one
#
# type=listener
#
# Service links the section to one of the service names used in this configuration
#
# 	service=<name of service section>
#
# Protocol is client protocol library name.
#
# 	protocol=[MySQLClient|telnetd|HTTPD|maxscaled]
#
# Port and address specify which port the service listens and the address limits
# listening to a specific network interface only. Address is optional.
#
# 	port=<Listening port>
#	address=<Address to bind to>
#
# Socket is alternative for address. The specified socket path must be writable
# by the Unix user MaxScale runs as.
#
#	socket=<Listening socket>
#
## Examples:

[RW Split Listener]
type=listener
service=RW Split Router
protocol=MySQLClient
port=4006
socket=/var/lib/maxscale/rwsplit.sock

[Write Connection Listener]
type=listener
service=Write Connection Router
protocol=MySQLClient
port=4007
socket=/var/lib/maxscale/writeconn.sock

[Read Connection Listener]
type=listener
service=Read Connection Router
protocol=MySQLClient
port=4008
socket=/var/lib/maxscale/readconn.sock

[CLI Listener]
type=listener
service=CLI
protocol=maxscaled
socket=/tmp/maxadmin.sock

## Definition of the servers
#
# Type specifies the section as server one
#
#	type=server
#
# The IP address or hostname of the machine running the database server that is
# being defined. MaxScale will use this address to connect to the backend
# database server.
#
#	address=<IP|hostname>
#
# The port on which the database listens for incoming connections. MaxScale
# will use this port to connect to the database server.
#
# 	port=<port>
#
# The name for the protocol module to use to connect MaxScale to the database.
# Currently the only backend protocol supported is the MySQLBackend module.
#
#	protocol=MySQLBackend
#
## Examples:


EOF

echo 'creating configuration'
exec "$@"
