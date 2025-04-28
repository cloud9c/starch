class PublicController < ApplicationController
  layout "public"
  allow_unauthenticated_access
end
