domain = domain.test.web

config.baseURL = http://{$domain}/
config.logfile = domain.test.web.log

config.no_cache = 1

version {
	comment = domain.test.web
	display = block
}

plugin.tx_solr {
	solr {
		scheme = http
		host = localhost
		port = 8180
		path = /solr/core_nl/
	}
}
