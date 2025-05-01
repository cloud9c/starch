class ErrorsController < ApplicationController
  allow_unauthenticated_access
  VALID_STATUS_CODES = %w[
    400 401 402 403 404 405 406 407 408 409 410
    411 412 413 414 415 416 417 418 421 422 423
    424 425 426 428 429 431 451 500
  ].freeze

  def show
    status_code = VALID_STATUS_CODES.include?(params[:code]) ? params[:code] : 500
    respond_to do |format|
      format.html { render status: status_code }
      format.any { head status_code }
    end
  end
end
