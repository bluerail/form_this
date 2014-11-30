require 'spec_helper'

describe FormThis do
  include FormThisSpecHelper

  it 'test' do
    form = make_form '
    def set_defaults
      @record.v1 = "TEST"
    end
    ', :v1, v2: { type: Integer }
    p form

    form = make_form '', :xxxx, :yyyyyyyyy
    p form
  end
end
