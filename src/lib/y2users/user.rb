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

require "yast2/execute"

module Y2Users
  # Representing user configuration on system in contenxt of given User Configuration
  # @note Immutable class.
  class User
    # @return [Y2Users::Configuration] reference to configuration in which it lives
    attr_reader :configuration

    # @return [String] user name
    attr_reader :name

    # @return [String, nil] user ID or nil if it is not yet assigned
    attr_reader :uid

    # @return [String, nil] primary group ID or nil if it is not yet assigned
    # @note to get primary group use method #primary_group
    attr_reader :gid

    # @return [String, nil] default shell or nil if it is not yet assigned
    attr_reader :shell

    # @return [String, nil] home directory or nil if it is not yet assigned
    attr_reader :home

    # @return [Array<String>] Fields in GECOS entry
    attr_reader :gecos

    # @return [:local, :ldap, :unknown] where is user defined
    attr_reader :source

    # @see respective attributes for possible values
    def initialize(configuration, name,
      uid: nil, gid: nil, shell: nil, home: nil, gecos: [], source: :unknown)
      # TODO: GECOS
      @configuration = configuration
      @name = name
      @uid = uid
      @gid = gid
      @shell = shell
      @home = home
      @source = source
      @gecos = gecos
    end

    # @return [Y2Users::Group, nil] primary group set to given user or
    #   nil if group is not set yet
    def primary_group
      configuration.groups.find { |g| g.gid == gid }
    end

    # @return [Array<Y2Users::Group>] list of groups where is user included including primary group
    def groups
      configuration.groups.select { |g| g.users.include?(self) }
    end

    # @return [Y2Users::Password] Password configuration assigned to user
    def password
      configuration.passwords.find { |p| p.name == name }
    end

    # @return [String] Returns full name from gecos entry or username if not specified in gecos.
    def full_name
      gecos.first || name
    end

    ATTRS = [:name, :uid, :gid, :shell, :home].freeze

    # Clones user to different configuration object.
    # @return [Y2Users::User] newly cloned user object
    def clone_to(configuration)
      attrs = ATTRS.each_with_object({}) { |a, r| r[a] = public_send(a) }
      attrs.delete(:name) # name is separate argument
      self.class.new(configuration, name, attrs)
    end

    # Compares user object if all attributes are same excluding configuration reference.
    # @return [Boolean] true if it is equal
    def ==(other)
      # do not compare configuration to allow comparison between different configs
      ATTRS.all? { |a| public_send(a) == other.public_send(a) }
    end
  end
end
