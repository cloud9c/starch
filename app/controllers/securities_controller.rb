class SecuritiesController < ApplicationController
  def show
    @passkeys = Current.user.webauthn_credentials.all
  end
end
