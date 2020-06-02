from json import dumps

from core import output
from core.config import CONFIG

from hpfeeds.twisted import ClientSessionService

from twisted.internet import endpoints, reactor, ssl

class Output(output.Output):

    def start(self):
        self.channel = CONFIG.get('output_hpfeed', 'channel', fallback='elasticpot')

        if CONFIG.has_option('output_hpfeed', 'endpoint'):
            endpoint = CONFIG.get('output_hpfeed', 'endpoint')
        else:
            server = CONFIG.get('output_hpfeed', 'server')
            port = CONFIG.getint('output_hpfeed', 'port')

            if CONFIG.has_option('output_hpfeed', 'tlscert'):
                with open(CONFIG.get('output_hpfeed', 'tlscert')) as fp:
                    authority = ssl.Certificate.loadPEM(fp.read())
                options = ssl.optionsForClientTLS(server, authority)
                endpoint = endpoints.SSL4ClientEndpoint(reactor, server, port, options)
            else:
                endpoint = endpoints.HostnameEndpoint(reactor, server, port)

        try:
            self.tags = [tag.strip() for tag in CONFIG.get('output_hpfeed', 'tags').split(',')]
        except Exception as e:
            self.tags = []

        ident = CONFIG.get('output_hpfeed', 'identifier')
        secret = CONFIG.get('output_hpfeed', 'secret')

        self.client = ClientSessionService(endpoint, ident, secret)
        self.client.startService()

    def stop(self):
        self.client.stopService()

    def write(self, event):
        event['tags'] = self.tags
        if 'payload' in event.keys():
            try:
                event['payload'] = event['payload'].decode('utf-8')
            except (UnicodeDecodeError, AttributeError):
                pass
        self.client.publish(self.channel, dumps(event).encode('utf-8'))
