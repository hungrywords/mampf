# TermsController
class TermsController < ApplicationController
  before_action :set_term, only: [:destroy, :edit, :update]
  authorize_resource
  layout 'administration'

  def index
    @terms = Term.order(:year).reverse_order.page params[:page]
  end

  def destroy
    @term.destroy
    redirect_to terms_path
  end

  def new
    @term = Term.new
  end

  def create
    @term = Term.new(term_params)
    @term.save
    if @term.valid?
      redirect_to terms_path
      return
    end
    @errors = @term.errors[:season].join(', ')
    render :update
  end

  def edit
  end

  def update
    @term.update(term_params)
    @errors = @term.errors[:season].join(', ') unless @term.valid?
  end

  def cancel
    @id = params[:id]
    @term = Term.find_by_id(@id)
    @new_action = params[:new] == 'true'
  end

  private

  def set_term
    @id = params[:id]
    @term = Term.find_by_id(@id)
    return if @term
    redirect_to terms_path, alert: I18n.t('controllers.no_term')
  end

  def term_params
    params.require(:term).permit(:year, :season)
  end
end
