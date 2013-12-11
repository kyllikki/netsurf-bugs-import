#!/usr/bin/env python

import json
import os
import sys
import urllib2
import urlparse

def main(jsonfile, targetdir):
    abstarget = os.path.realpath(targetdir)

    if not os.path.exists(abstarget):
        os.makedirs(abstarget)

    with open(jsonfile, 'r') as jsonf:
        descriptor = json.load(jsonf)

    for ticket in descriptor['tickets']:
        ticket_id = ticket['discussion_thread']['_id']
        attachments = []
        for post in ticket['discussion_thread']['posts']:
            for attachment in post['attachments']:
                attachments.append(attachment['url'])

        ticket_dir = os.path.join(abstarget, ticket_id)
        os.mkdir(ticket_dir)

        print "Processing ticket ", ticket_id

        for attachment in attachments:
            name = urlparse.urlparse(attachment).path.split('/')[-1]
            target = os.path.join(ticket_dir, name)

            if os.path.exists(target):
                raise RuntimeError("Target %s already exists!" % ( target, ))

            print "    Fetching attachment ", attachment

            with open(target, 'wb') as outf:
               response = urllib2.urlopen(attachment)
               outf.write(response.read())

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
~                                                                                                                                                                                                                                            
~