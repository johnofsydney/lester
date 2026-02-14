module Constants
  extend ActiveSupport::Concern
  PAGE_LIMIT = 25
  MAX_SEARCH_DEPTH = 4

  TOO_MANY_CONNECTIONS_THRESHOLD = 3000

  # Experimental feature: if there are > 100 direct transfers, stop searching deeper
  # this applies at each level of recursion, so if there are 10 transfers at depth 0, 50 at depth 1 and 50 at depth 2, it will not go to depth 3
  DIRECT_TRANSFERS_COUNT_THRESHOLD = 100

  PLEASE_REFRESH_MESSAGE = ' Building cached data. Please refresh in a moment.'.freeze
  TOO_MANY_CONNECTIONS_MESSAGE = 'Too many connections. Cannot display.'.freeze

  MAX_NODE_COUNT_FIRST_DEGREE_CONNECTIONS = 200
  MAX_NODE_COUNT_TO_FOLLOW = 50
  MAX_DESCENDENTS_RESULTS = 1500

  CONTROLLER_RATE_LIMIT = 25
end
