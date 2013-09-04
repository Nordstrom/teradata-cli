require '../lib/configuration'
require "test/unit"

class TestConfigurtion < Test::Unit::TestCase
 
  def test_basic_load
  	config = Configuration.new({'foo' => 1, 'foo2' => 'string' }, { 'foo' => 2 })

  	assert_equal(2, config['foo'])
  	assert_equal('string', config['foo2'])
  end

  def test_hosts_override
  	args1 = {
  		'hosts'=> {
  			'host1'=> {
  				'username' => 'bob',
  				'password' => 'bob_pass'
  			},
  			'host2' => {
  				'username' => 'sam',
  				'password' => 'sam_pass'
  			}
  		}
  	}

  	args2 = {
  		'hosts' => {
  			'host2' => {
  				'username' => 'jim',
  				'password' => 'jim_pass'
  			},
  			'host3' => {
  				'username' => 'frank',
  				'password' => 'frank_pass'
  			}
  		}
  	}

  	config = Configuration.new(args1, args2)
  	assert_equal(3, config['hosts'].length)
  	assert_not_nil(config['hosts']['host2'])
  	assert_equal('jim', config['hosts']['host2']['username'])
  end

  def test_load_conf_file()
  	config = Configuration.new('tdsql.conf', 'fake.conf')
  	assert_equal(120, config['timeout'])
  end

  def test_get_active_host_explicit()
  	host_config = {'hostname' => 'host', 'username' => 'bob', 'password' => 'pass'}
  	config = Configuration.new(host_config)
  	host = config.get_active_host()
  	assert_not_nil(host)
  	assert_equal(host, host_config)
  end

  def test_get_host_default()
  	hash = {
  		'hosts'=> {
  			'host1'=> {
  				'username' => 'bob',
  				'password' => 'bob_pass'
  			},
  			'host2' => {
  				'username' => 'sam',
  				'password' => 'sam_pass'
  			}
  		}
  	}

		config = Configuration.new(hash)
		host = config.get_active_host()

  	assert_not_nil(host)
  	assert_equal('host1', host['hostname'])
  	assert_equal('bob', host['username'])
  	assert_equal('bob_pass', host['password'])
  end

  def test_missing_hosts()
  	config = Configuration.new({})
  	assert_raise(ConfigError) { config.get_active_host() }
  end

  def test_missing_hostname()
  	hosts_config = {
  		'host1' => {
  			'username' => 'bob',
  			'password' => 'pass'
  		}
  	}
  	config = Configuration.new({'hosts' => hosts_config, 'host' => 'fakehost' })
  	assert_raise(ConfigError) { config.get_active_host() }
  end

  def test_host_by_hostname()
  	hosts_config = {
  		'host1' => {
  			'username' => 'bob',
  			'password' => 'pass'
  		}
  	}
  	config = Configuration.new({'hosts' => hosts_config, 'host' => 'host1' })
  	host = config.get_active_host()
  	assert_equal('host1', host['hostname'])
  	assert_equal('bob', host['username'])
  	assert_equal('pass', host['password'])
  end
end