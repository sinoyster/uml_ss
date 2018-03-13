#!/bin/sh
# Copyright (c) 2012-2015 The OpenRC Authors.
# See the Authors file at the top-level directory of this distribution and
# https://github.com/OpenRC/openrc/blob/master/AUTHORS
#
# This file is part of OpenRC. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/OpenRC/openrc/blob/master/LICENSE
# This file may not be copied, modified, propagated, or distributed
#    except according to the terms contained in the LICENSE file.

. "/lib/rc/sh/functions.sh"

if [ -e /run/openrc/softlevel ]; then
	einfo "The OpenRC dependency data has already been migrated."
	exit 0
fi

if [ ! -d /run ]; then
	eerror "/run is not a directory."
	eerror "moving /run to /run.pre-openrc"
	mv /run /run.pre-openrc
	mkdir /run
fi

rm -rf /run/openrc

if ! mountinfo -q -f tmpfs /run; then
	ln -s "/lib/rc"/init.d /run/openrc
else
	cp -a "/lib/rc/init.d" /run/openrc
	rc-update -u
fi

einfo "The OpenRC dependency data was migrated successfully."
exit 0
