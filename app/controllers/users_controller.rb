class UsersController < ApplicationController
  def destroy
    Current.user.destroy
    redirect_to new_session_path
  end
end
