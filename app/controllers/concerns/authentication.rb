module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    before_action :resume_session
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session && Current.session&.user_id?
    end

    def require_authentication
      authenticated? || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie || start_new_session
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id])
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session
      reset_session
      Session.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
        session
      end
    end

    def authenticate_session_for(user)
      resume_session && Current.session.update!(user: user)
    end

    def terminate_session
      verifications = Verification.where(session_id: Current.session.id)
      verifications.destroy_all
      reset_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
