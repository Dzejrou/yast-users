#!/usr/bin/env rspec

# Copyright (c) [2021] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require_relative "../test_helper"

require "y2users/config"
require "y2users/linux/reader"

describe Y2Users::Linux::Reader do
  before do
    # mock Yast::Execute calls and provide file content from fixture
    passwd_content = File.read(File.join(FIXTURES_PATH, "/root/etc/passwd"))
    allow(Yast::Execute).to receive(:on_target!).with(/getent/, "passwd", anything)
      .and_return(passwd_content)

    group_content = File.read(File.join(FIXTURES_PATH, "/root/etc/group"))
    allow(Yast::Execute).to receive(:on_target!).with(/getent/, "group", anything)
      .and_return(group_content)

    shadow_content = File.read(File.join(FIXTURES_PATH, "/root/etc/shadow"))
    allow(Yast::Execute).to receive(:on_target!).with(/getent/, "shadow", anything)
      .and_return(shadow_content)
  end

  describe "#read_to" do
    it "fills given config with read data" do
      config = Y2Users::Config.new
      subject.read_to(config)

      expect(config.users.size).to eq 18
      expect(config.groups.size).to eq 37

      root_user = config.users.find { |u| u.uid == "0" }
      expect(root_user.shell).to eq "/bin/bash"
      expect(root_user.primary_group.name).to eq "root"
      expect(root_user.password.value.encrypted?).to eq true
      expect(root_user.password.value.content).to match(/^\$6\$pL/)
    end
  end
end
