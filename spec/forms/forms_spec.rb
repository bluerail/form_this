require 'spec_helper'

describe FormThis do
  include FormThisSpecHelper

  describe 'self.property' do
    it 'with only a name' do
      form = make_form :value

      expect(form.value).to be_nil
      expect(form.record.value).to be_nil

      form.value = 'the filthy human larva lies!'
      expect(form.value).to eq('the filthy human larva lies!')
      expect(form.record.value).to be_nil
    end

    it 'with a type' do
      form = make_form value: { type: Integer }

      form.value = '666.1'
      expect(form.value).to eq(666)
      expect(form.record.value).to be_nil

      form.value = 'six'
      expect(form.value).to eq('six')
      expect(form.record.value).to be_nil
    end

    it 'with validations' do
      form = make_form value: { type: Integer, validates: { numericality: { greater_than: 665 } } }

      form.value = 'six'
      expect(form).to_not be_valid

      form.value = '665'
      expect(form).to_not be_valid

      form.value = 666
      expect(form).to be_valid
      expect(form.value).to eq(666)
      expect(form.record.value).to be_nil
    end
  end


  describe 'self.properties' do
    it 'with 2 values' do
      form = make_form :value1, :value2
      expect(form.value1).to be_nil
      expect(form.value2).to be_nil
    end
  end


  describe 'form_for builder' do
  end


  describe 'protect_form_for' do
  end


  describe 'persist!' do
  end


  describe 'validate' do
  end


  describe 'update_record' do
  end


  describe 'save' do
  end


  describe 'save!' do
  end
end
