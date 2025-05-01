module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
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
      return if authenticated?
      session[:redirect_url] = request.path

      if hotwire_native_app?
        redirect_to redirect_path(url: new_session_path) and return
      end

      redirect_to new_session_path
    end

    def resume_session
      Current.session ||= find_session_by_cookie || start_new_session
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id])
    end

    def start_new_session
      reset_session
      Session.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
        session
      end
    end

    def generate_verification_for(user)
      magic_link_token = user.generate_magic_link
      verification = user.generate_verification

      unless user.send_login_email(magic_link_token, verification.code)
        @flash = { alert: "We couldn't send your login email at this time. Please try again later." }
        nil
      end
    end

    def authenticate_session(token, verification_code)
      user = if token.present?
        User.find_by_token_for(:magic_link, token)
      elsif verification_code.present?
        Verification.find_user(Current.session.id, verification_code)
      end

      if user.present?
        resume_session && Current.session.update!(user: user)
        user.verify
      end

      user.present?
    end

    def destroy_session
      verifications = Verification.where(session_id: Current.session.id)
      verifications.destroy_all
      reset_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
