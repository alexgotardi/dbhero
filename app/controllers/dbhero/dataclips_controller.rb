require_dependency "dbhero/application_controller"

module Dbhero
  class DataclipsController < ApplicationController
    before_action :check_auth, except: [:show]
    before_action :set_dataclip, only: [:show, :edit, :update, :destroy]
    respond_to :html, :csv

    def index
      @dataclips = Dataclip.all
    end

    def show
      check_auth if @dataclip.private?
      @dataclip.query_result

      respond_to do |format|
        format.html
        format.csv do
          send_data @dataclip.csv_string, type: Mime::CSV, disposition: "attachment; filename=#{@dataclip.token}.csv"
        end
      end
    end

    def new
      @dataclip = Dataclip.new
    end

    def edit
      @dataclip.check_query
    end

    def create
      @dataclip = Dataclip.create(dataclip_params)
      respond_with @dataclip, location: edit_dataclip_path(@dataclip),notice: 'Dataclip was successfully created.'
    end

    def update
      @dataclip.update(dataclip_params)
      respond_with @dataclip, location: edit_dataclip_path(@dataclip), notice: 'Dataclip was successfully updated.'
    end

    def destroy
      @dataclip.destroy
      redirect_to dataclips_url, notice: 'Dataclip was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_dataclip
        @dataclip = Dataclip.find_by_token(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def dataclip_params
        params.require(:dataclip).permit(:description, :raw_query)
      end

      def check_auth
        if Dbhero.authenticate
          unless _current_user && call_custom_auth
            raise ActionController::RoutingError.new('Forbidden')
          end
        end
      end

      def user_representation
        _current_user.send(Dbhero.user_representation) if _current_user
      end

      def _current_user
        if Dbhero.current_user_method.present?
          send(Dbhero.current_user_method)
        end
      end

      def call_custom_auth
        cond = Dbhero.custom_user_auth_condition
        cond.call(_current_user) if cond.present? && cond.is_a?(Proc)
      end
  end
end
