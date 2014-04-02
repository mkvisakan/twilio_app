class FunDataController < ApplicationController
  before_action :set_fun_datum, only: [:show, :edit, :update, :destroy]

  # GET /fun_data
  # GET /fun_data.json
  def index
    @fun_data = FunDatum.all
  end

  # GET /fun_data/1
  # GET /fun_data/1.json
  def show
  end

  # GET /fun_data/new
  def new
    @fun_datum = FunDatum.new
  end

  # GET /fun_data/1/edit
  def edit
  end

  # POST /fun_data
  # POST /fun_data.json
  def create
    @fun_datum = FunDatum.new(fun_datum_params)

    respond_to do |format|
      if @fun_datum.save
        format.html { redirect_to @fun_datum, notice: 'Fun datum was successfully created.' }
        format.json { render action: 'show', status: :created, location: @fun_datum }
      else
        format.html { render action: 'new' }
        format.json { render json: @fun_datum.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fun_data/1
  # PATCH/PUT /fun_data/1.json
  def update
    respond_to do |format|
      if @fun_datum.update(fun_datum_params)
        format.html { redirect_to @fun_datum, notice: 'Fun datum was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @fun_datum.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fun_data/1
  # DELETE /fun_data/1.json
  def destroy
    @fun_datum.destroy
    respond_to do |format|
      format.html { redirect_to fun_data_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fun_datum
      @fun_datum = FunDatum.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def fun_datum_params
      params.require(:fun_datum).permit(:id, :type, :story)
    end
end
