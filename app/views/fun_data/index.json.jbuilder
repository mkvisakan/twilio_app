json.array!(@fun_data) do |fun_datum|
  json.extract! fun_datum, :id, :id, :type, :story
  json.url fun_datum_url(fun_datum, format: :json)
end
