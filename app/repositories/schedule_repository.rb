# This file is only to hold modules that are contained
# by TeamRepository. No methods for TeamRepository should
# be added here.
#
# The objective is to keep namespaces to two (2) levels, such as
#
# TeamRepository::RosterRepository
#
# as opposed to
#
# OrganizationRepository::TeamRepository::RosterRepository
#
module ScheduleRepository
	extend Edr::AR::Repository
	extend CommonFinders::OrientGraph
	set_model_class Schedule
end
