#!/usr/bin/python

# Copyright (c) 2017 Microsoft Corporation

ANSIBLE_METADATA = {
	'metadata_version': '1.1',
	'supported_by': 'community',
	'status': ['preview']
}

DOCUMENTATION = '''
---
module: mssql_conf

short_description: Set configuration settings for a SQL Server instance

description:
	- Set configuration settings for a SQL Server instance

version_added: "2.2"

author: Arnav Singh (@arsing)

options:
	setup_sa_password:
		description:
			- The password to set for the sa account in setup
		required: false

	name:
		description:
			- The name of the setting
		required: false

	value:
		description:
			- The value of the setting
		required: false

	login_port:
		description:
			- The TDS port of the instance
		required: false
		default: 1433


	login_name:
		description:
			- The name of the user to log in to the instance
		required: true

	login_password:
		description:
			- The password of the user to log in to the instance
		required: true

requirements:
	- python >= 2.7
'''.replace('\t', '  ')

EXAMPLES = '''
# Enables HADRON
- mssql_conf:
	name: hadr.hadrenabled
	value: 1
	login_name: sa
	login_password: password
'''.replace('\t', '  ')

RETURN = '''
#
'''.replace('\t', '  ')


from ansible.module_utils.basic import AnsibleModule
import os.path
import re
import subprocess

def main():
	module = AnsibleModule(
		argument_spec = dict(
			setup_sa_password = dict(required = False, no_log = True),
			setup_pid = dict(required = False),
			name = dict(required = False),
			value = dict(required = False),
			traceflags_on = dict(type = 'list', required = False),
			traceflags_off = dict(type = 'list', required = False),
			login_port = dict(required = False, default = 1433),
			login_name = dict(required = True),
			login_password = dict(required = True, no_log = True)
		),
		required_one_of = [
			['setup_sa_password', 'name', 'traceflags_on', 'traceflags_off']
		],
		mutually_exclusive = [
			['setup_sa_password', 'name', 'traceflags_on'],
			['setup_sa_password', 'name', 'traceflags_off'],
		],
		required_together = [
			['setup_sa_password', 'setup_pid'],
			['name', 'value']
		],
	)

	setup_sa_password = module.params['setup_sa_password']
	setup_pid = module.params['setup_pid']
	name = module.params['name']
	value = module.params['value']
	traceflags_on = module.params['traceflags_on']
	traceflags_off = module.params['traceflags_off']
	login_port = module.params['login_port']
	login_name = module.params['login_name']
	login_password = module.params['login_password']

	changed = True

	if setup_sa_password is not None:
		need_to_set_up = True
		if os.path.isfile('/var/opt/mssql/mssql.conf'):
			with open("/var/opt/mssql/mssql.conf", "r") as mssql_conf_file:
				mssql_conf_file_data = mssql_conf_file.read()
			if re.search(r'\b(accepteula)\b', mssql_conf_file_data, re.I) is not None:
				need_to_set_up = False
				changed = False
		if need_to_set_up:
			setup_env = os.environ.copy()
			setup_env.update({ 'MSSQL_SA_PASSWORD': setup_sa_password, 'MSSQL_PID': setup_pid })
			subprocess.check_call(
				['/opt/mssql/bin/mssql-conf', '--noprompt', 'setup', 'accept-eula'],
				env = setup_env)

	if name is not None:
		subprocess.check_call(['/opt/mssql/bin/mssql-conf', '--noprompt', 'set', name, value])

	if traceflags_on is not None:
		subprocess.check_call(['/opt/mssql/bin/mssql-conf', '--noprompt', 'traceflag'] + [str(traceflag) for traceflag in traceflags_on] + ['on'])

	if traceflags_off is not None:
		subprocess.check_call(['/opt/mssql/bin/mssql-conf', '--noprompt', 'traceflag'] + [str(traceflag) for traceflag in traceflags_off] + ['off'])

	module.exit_json(changed = changed)

if __name__ == '__main__':
	main()
