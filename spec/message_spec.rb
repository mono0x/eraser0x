# -*- coding: utf-8 -*-

require_relative 'spec_helper'

describe Eraser::Message do
  describe '.random' do
    context 'when empty' do
      before do
        Eraser::Database.migrate!
      end

      it 'should raise exception' do
        lambda { Eraser::Message.random(Random.new) }.should raise_error(RuntimeError)
      end
    end

    context 'when not empty' do
      before do
        Eraser::Database.migrate!
        create :ramuramu_message
        create :pikipiki_message
      end

      context 'when Random.rand is 0' do
        before do
          @random = double('random')
          @random.stub(:rand) { 0 }
        end

        it 'should return ramuramu_message' do
          Eraser::Message.random(@random).should == Eraser::Message.get(1)
        end
      end

      context 'when Random.rand is 1' do
        before do
          @random = double('random')
          @random.stub(:rand) { 1 }
        end

        it 'should return pikipiki_message' do
          Eraser::Message.random(@random).should == Eraser::Message.get(2)
        end
      end
    end
  end
end
