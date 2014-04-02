require 'test_helper'

class FunDataControllerTest < ActionController::TestCase
  setup do
    @fun_datum = fun_data(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fun_data)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fun_datum" do
    assert_difference('FunDatum.count') do
      post :create, fun_datum: { id: @fun_datum.id, story: @fun_datum.story, type: @fun_datum.type }
    end

    assert_redirected_to fun_datum_path(assigns(:fun_datum))
  end

  test "should show fun_datum" do
    get :show, id: @fun_datum
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @fun_datum
    assert_response :success
  end

  test "should update fun_datum" do
    patch :update, id: @fun_datum, fun_datum: { id: @fun_datum.id, story: @fun_datum.story, type: @fun_datum.type }
    assert_redirected_to fun_datum_path(assigns(:fun_datum))
  end

  test "should destroy fun_datum" do
    assert_difference('FunDatum.count', -1) do
      delete :destroy, id: @fun_datum
    end

    assert_redirected_to fun_data_path
  end
end
