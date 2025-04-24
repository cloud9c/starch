class UsersController < ApplicationController
  def destroy
    Current.user.destroy
    destroy_session
    redirect_to new_session_path
  end
end
