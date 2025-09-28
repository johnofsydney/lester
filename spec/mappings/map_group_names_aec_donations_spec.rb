require 'rails_helper'
require 'spec_helper'

RSpec.describe MapGroupNamesAecDonations, type: :service do
  describe '#call' do
    it 'returns "Get Up Limited" for names containing "GetUp" or "Get Up"' do
      expect(described_class.new.call('GetUp Foo')).to eq('Get Up Limited')
      expect(described_class.new.call('Get Up Limited')).to eq('Get Up Limited')
    end

    it 'returns "Australian Hotels Association" for names containing "Australian Hotels Association"' do
      expect(described_class.new.call('Australian Hotels Association')).to eq('Australian Hotels Association')
    end

    it 'returns "Advance Australia" for names containing "Advance Aus" or similar' do
      expect(described_class.new.call('Advance Aus')).to eq('Advance Australia')
      expect(described_class.new.call('Advanced Aus')).to eq('Advance Australia')
      expect(described_class.new.call('Advance')).to eq('Advance Australia')
    end

    it 'returns "It\'s Not a Race Limited" for names containing "Not A Race"' do
      expect(described_class.new.call('Not A Race')).to eq("It's Not a Race Limited")
    end

    it 'returns "Australian Council of Trade Unions" for names containing "ACTU"' do
      expect(described_class.new.call('ACTU')).to eq('Australian Council of Trade Unions')
    end

    it 'returns "Climate 200 Pty Ltd" for names containing "Climate 200"' do
      expect(described_class.new.call('Climate 200')).to eq('Climate 200 Pty Ltd')
      expect(described_class.new.call('Climate200')).to eq('Climate 200 Pty Ltd')
    end

    it 'returns "Australian Chamber of Commerce and Industry" for names containing variations of "Australian Chamber of Commerce and Industry"' do
      expect(described_class.new.call('Australian Chamber of Commerce and Industry')).to eq('Australian Chamber of Commerce and Industry')
      expect(described_class.new.call('Australia Chamber of Commerce and Industry')).to eq('Australian Chamber of Commerce and Industry')
    end

    it 'returns "Hadley Holdings Pty Ltd" for names containing "Hadley Holdings"' do
      expect(described_class.new.call('Hadley Holdings')).to eq('Hadley Holdings Pty Ltd')
    end

    it 'returns "University of NSW" for names containing "University of NSW" or similar' do
      expect(described_class.new.call('University of NSW')).to eq('University of NSW')
      expect(described_class.new.call('UNSW')).to eq('University of NSW')
    end

    it 'returns "Australian Communities Foundation Limited" for names containing "Australian Communities Foundation"' do
      expect(described_class.new.call('Australian Communities Foundation')).to eq('Australian Communities Foundation Limited')
    end

    it 'returns "Australians for Unity Ltd" for names containing "Australians for Unity"' do
      expect(described_class.new.call('Australians for Unity')).to eq('Australians for Unity Ltd')
      expect(described_class.new.call('Australian for Unity')).to eq('Australians for Unity Ltd')
      expect(described_class.new.call('Australia for Unity')).to eq('Australians for Unity Ltd')
      expect(described_class.new.call('AFUL')).to eq('Australians for Unity Ltd')
    end

    it 'returns "Australians for Indigenous Constitutional Recognition" for names containing variations of "Australians for Indigenous Constitutional Recognition"' do
      expect(described_class.new.call('Australians for Indigenous Constitutional Recognition')).to eq('Australians for Indigenous Constitutional Recognition')
      expect(described_class.new.call('Australians for Indigenous Constitution Recognition')).to eq('Australians for Indigenous Constitutional Recognition')
      expect(described_class.new.call('Australians for Indigenous Constitution Recongition')).to eq('Australians for Indigenous Constitutional Recognition')
      expect(described_class.new.call('AICR')).to eq('Australians for Indigenous Constitutional Recognition')
      expect(described_class.new.call('aicr')).to eq('Australians for Indigenous Constitutional Recognition')
    end

    it 'returns "Climate Action Network Australia" for names containing "Climate Action Network Australia"' do
      expect(described_class.new.call('Climate Action Network Australia')).to eq('Climate Action Network Australia')
    end

    it 'returns "Stand UP: Jewish Commitment TO A Better World" for names containing "Stand UP: Jewish Commitment TO A Better World"' do
      expect(described_class.new.call('Stand UP: Jewish Commitment TO A Better World')).to eq('Stand UP: Jewish Commitment TO A Better World')
    end

    it 'returns "The Australia Institute" for names containing "Australia Institute"' do
      expect(described_class.new.call('Australia Institute')).to eq('The Australia Institute')
      expect(described_class.new.call('The Australia Institute')).to eq('The Australia Institute')
    end

    it 'returns "The Dugdale Trust for Women and Girls" for names containing "The Dugdale Trust for Women and Girls"' do
      expect(described_class.new.call('The Dugdale Trust for Women and Girls')).to eq('The Dugdale Trust for Women and Girls')
    end

    it 'returns "Uphold and Recognise Limited" for names containing "Uphold and Recognise"' do
      expect(described_class.new.call('Uphold and Recognise')).to eq('Uphold and Recognise Limited')
    end

    it 'returns "Keldoulis Investments Pty Ltd" for names containing "Keldoulis Investments"' do
      expect(described_class.new.call('Keldoulis Investments')).to eq('Keldoulis Investments Pty Ltd')
    end

    it 'returns "Turner Components Pty Ltd" for names containing "Turner Components"' do
      expect(described_class.new.call('Turner Components')).to eq('Turner Components Pty Ltd')
    end

    it 'returns "Glencore Australia" for names containing "Glencore Australia"' do
      expect(described_class.new.call('Glencore Australia')).to eq('Glencore Australia')
    end

    it 'returns "Whitehaven Coal Limited" for names containing "Whitehaven Coal"' do
      expect(described_class.new.call('Whitehaven Coal')).to eq('Whitehaven Coal Limited')
    end

    it 'returns "Woodside Energy" for names containing "Woodside Energy"' do
      expect(described_class.new.call('Woodside Energy')).to eq('Woodside Energy')
    end

    it 'returns "Origin Energy" for names containing "Origin Energy"' do
      expect(described_class.new.call('Origin Energy')).to eq('Origin Energy')
    end

    it 'returns "Sentinel Property Group" for names containing "Sentinel Property Group"' do
      expect(described_class.new.call('Sentinel Property Group')).to eq('Sentinel Property Group')
    end

    it 'returns "Chevron Australia Pty Ltd" for names containing "Chevron Australia"' do
      expect(described_class.new.call('Chevron Australia')).to eq('Chevron Australia Pty Ltd')
    end

    it 'returns "Inpex Corporation" for names containing "Inpex"' do
      expect(described_class.new.call('Inpex')).to eq('Inpex Corporation')
    end

    it 'returns "Barton Deakin Pty Ltd" for names containing "Barton Deakin"' do
      expect(described_class.new.call('Barton Deakin')).to eq('Barton Deakin Pty Ltd')
    end

    it 'returns "Mineralogy Pty Ltd" for names containing "Mineralogy"' do
      expect(described_class.new.call('Mineralogy')).to eq('Mineralogy Pty Ltd')
    end

    it 'returns "Bluescope Steel Limited" for names containing "Bluescope Steel"' do
      expect(described_class.new.call('Bluescope Steel')).to eq('Bluescope Steel Limited')
    end

    it 'returns "Gilbert & Tobin" for names containing "Gilbert & Tobin"' do
      expect(described_class.new.call('Gilbert & Tobin')).to eq('Gilbert & Tobin')
      expect(described_class.new.call('Gilbert and Tobin')).to eq('Gilbert & Tobin')
    end

    it 'returns "JMR Management Consultancy Services Pty Ltd" for names containing "JMR Management Consultancy"' do
      expect(described_class.new.call('JMR Management Consultancy')).to eq('JMR Management Consultancy Services Pty Ltd')
    end

    it 'returns "NIB Health Funds Limited" for names containing "NIB Health Funds"' do
      expect(described_class.new.call('NIB Health Funds')).to eq('NIB Health Funds Limited')
    end

    it 'returns "Pricewaterhousecoopers" for names containing "Pricewaterhousecoopers"' do
      expect(described_class.new.call('Pricewaterhousecoopers')).to eq('Pricewaterhousecoopers')
    end

    it 'returns "CMAX Advisory" for names containing "CMAX Advisory" or "CMAX Communications"' do
      expect(described_class.new.call('CMAX Advisory')).to eq('CMAX Advisory')
      expect(described_class.new.call('CMAX Communications')).to eq('CMAX Advisory')
    end

    it 'returns "Corporate Affairs Australia Pty Ltd" for names containing "Corporate Affairs Australia Pty Ltd" or "Corporate Affairs Advisory"' do
      expect(described_class.new.call('Corporate Affairs Australia Pty Ltd')).to eq('Corporate Affairs Australia Pty Ltd')
      expect(described_class.new.call('Corporate Affairs Advisory')).to eq('Corporate Affairs Australia Pty Ltd')
    end

    it 'returns "Hawker Britton Pty Ltd" for names containing "Hawker Britton Pty Ltd"' do
      expect(described_class.new.call('Hawker Britton Pty Ltd')).to eq('Hawker Britton Pty Ltd')
    end

    it 'returns "Pacific Partners Strategic Advocacy Pty Ltd" for names containing "Pacific Partners Strategic Advocacy Pty Ltd"' do
      expect(described_class.new.call('Pacific Partners Strategic Advocacy Pty Ltd')).to eq('Pacific Partners Strategic Advocacy Pty Ltd')
    end

    it 'returns "Probity International Pty Ltd" for names containing "Probity International Pty Ltd"' do
      expect(described_class.new.call('Probity International Pty Ltd')).to eq('Probity International Pty Ltd')
    end

    it 'returns "The Pharmacy Guild of Australia" for names containing "Pharmacy Guild"' do
      expect(described_class.new.call('Pharmacy Guild')).to eq('The Pharmacy Guild of Australia')
    end

    it 'returns "Your Solutions Compounding Pharmacy" for names containing "Your Solutions Compounding Pharmacy"' do
      expect(described_class.new.call('Your Solutions Compounding Pharmacy')).to eq('Your Solutions Compounding Pharmacy')
    end

    it 'returns "AGL Energy Limited" for names equal to "AGL"' do
      expect(described_class.new.call('AGL')).to eq('AGL Energy Limited')
    end

    it 'returns "AIA Australia" for names equal to "AIA"' do
      expect(described_class.new.call('AIA')).to eq('AIA Australia')
    end

    it 'returns "AMP Limited" for names equal to "AMP"' do
      expect(described_class.new.call('AMP')).to eq('AMP Limited')
    end

    it 'returns "Abbott Medical Australia Pty Ltd" for names equal to "Abbott"' do
      expect(described_class.new.call('Abbott')).to eq('Abbott Medical Australia Pty Ltd')
    end

    it 'returns "Abbvie Australia" for names containing "Abbvie"' do
      expect(described_class.new.call('Abbvie')).to eq('Abbvie Australia')
    end

    it 'returns "Adecco Australia" for names containing "Adecco Australia"' do
      expect(described_class.new.call('Adecco Australia')).to eq('Adecco Australia')
    end

    it 'returns "Afterpay Australia Pty Ltd" for names containing "Afterpay Pty Ltd"' do
      expect(described_class.new.call('Afterpay Pty Ltd')).to eq('Afterpay Australia Pty Ltd')
    end

    it 'returns "Agripower Australia Limited" for names containing "Agripower"' do
      expect(described_class.new.call('Agripower')).to eq('Agripower Australia Limited')
    end

    it 'returns "Amazon Web Services Australia Pty Ltd" for names containing "Amazon Web Services Australia" or "Amazon AWS WEB Services Australia Pty Ltd"' do
      expect(described_class.new.call('Amazon Web Services Australia')).to eq('Amazon Web Services Australia Pty Ltd')
      expect(described_class.new.call('Amazon AWS WEB Services Australia Pty Ltd')).to eq('Amazon Web Services Australia Pty Ltd')
    end

    it 'returns "Amazon Web Services Limited" for names containing "Amazon Web Services"' do
      expect(described_class.new.call('Amazon Web Services')).to eq('Amazon Web Services Limited')
    end

    it 'returns "Amazon Australia" for names containing "Amazon"' do
      expect(described_class.new.call('Amazon')).to eq('Amazon Australia')
    end

    it 'returns "Amgen Australia Pty Ltd" for names containing "Amgen Australia"' do
      expect(described_class.new.call('Amgen Australia')).to eq('Amgen Australia Pty Ltd')
    end

    it 'returns "Ampol Limited" for names containing "Ampol Ltd" or "Ampol Limited"' do
      expect(described_class.new.call('Ampol Ltd')).to eq('Ampol Limited')
      expect(described_class.new.call('Ampol Limited')).to eq('Ampol Limited')
    end

    it 'returns "Angus Knight Group" for names containing "Angus Knight Group", "Angus Knight Pty Ltd", or "Angus Knight Pty Limited"' do
      expect(described_class.new.call('Angus Knight Group')).to eq('Angus Knight Group')
      expect(described_class.new.call('Angus Knight Pty Ltd')).to eq('Angus Knight Group')
      expect(described_class.new.call('Angus Knight Pty Limited')).to eq('Angus Knight Group')
    end

    it 'returns "Arafura Rare Earths" for names containing "Arafura Rare Earths" or "Arafura Resources"' do
      expect(described_class.new.call('Arafura Rare Earths')).to eq('Arafura Rare Earths')
      expect(described_class.new.call('Arafura Resources')).to eq('Arafura Rare Earths')
    end

    it 'returns "Ausbiotech" for names containing "Ausbiotech"' do
      expect(described_class.new.call('Ausbiotech')).to eq('Ausbiotech')
    end

    it 'returns "Australian Capital Equity Pty Ltd" for names containing "Australian Capital Equity Pty Ltd" or "Australian Capital Equity P/L"' do
      expect(described_class.new.call('Australian Capital Equity Pty Ltd')).to eq('Australian Capital Equity Pty Ltd')
      expect(described_class.new.call('Australian Capital Equity P/L')).to eq('Australian Capital Equity Pty Ltd')
    end

    it 'returns "Australian Computer Society" for names containing "Australian Computer Society Incorporated"' do
      expect(described_class.new.call('Australian Computer Society Incorporated')).to eq('Australian Computer Society')
    end

    it 'returns "BP Australia Pty Ltd" for names containing "BP Australia Pty Ltd" or equal to "BP Australia"' do
      expect(described_class.new.call('BP Australia Pty Ltd')).to eq('BP Australia Pty Ltd')
      expect(described_class.new.call('BP Australia')).to eq('BP Australia Pty Ltd')
    end

    it 'returns "Bayer Australia Ltd" for names containing "Bayer Australia Ltd" or "Bayer Australia Limited"' do
      expect(described_class.new.call('Bayer Australia Ltd')).to eq('Bayer Australia Ltd')
      expect(described_class.new.call('Bayer Australia Limited')).to eq('Bayer Australia Ltd')
    end

    it 'returns "Beach Energy Limited" for names containing "Beach Energy"' do
      expect(described_class.new.call('Beach Energy')).to eq('Beach Energy Limited')
    end

    it 'returns "Bowen Coking Coal" for names containing "Bowen Coking Coal"' do
      expect(described_class.new.call('Bowen Coking Coal')).to eq('Bowen Coking Coal')
    end

    it 'returns "Bus Association of Victoria" for names containing "Bus Association of Victoria"' do
      expect(described_class.new.call('Bus Association of Victoria')).to eq('Bus Association of Victoria')
    end

    it 'returns "CAE Australia Pty Ltd" for names containing "CAE Australia" or equal to "CAE"' do
      expect(described_class.new.call('CAE Australia')).to eq('CAE Australia Pty Ltd')
      expect(described_class.new.call('CAE')).to eq('CAE Australia Pty Ltd')
    end

    it 'returns "CO2CRC" for names containing "CO2CRC"' do
      expect(described_class.new.call('CO2CRC')).to eq('CO2CRC')
    end

    it 'returns "Canberra Consulting" for names containing "Canberra Consulting"' do
      expect(described_class.new.call('Canberra Consulting')).to eq('Canberra Consulting')
    end

    it 'returns "Careflight" for names containing "Careflight"' do
      expect(described_class.new.call('Careflight')).to eq('Careflight')
    end

    it 'returns "Chevron Australia Pty Ltd" for names containing "Chevron"' do
      expect(described_class.new.call('Chevron')).to eq('Chevron Australia Pty Ltd')
    end

    it 'returns "Citigroup" for names containing "Citigroup"' do
      expect(described_class.new.call('Citigroup')).to eq('Citigroup')
    end

    it 'returns "Civmec Construction & Engineering Pty Ltd" for names containing "Civmec Construction & Engineering"' do
      expect(described_class.new.call('Civmec Construction & Engineering')).to eq('Civmec Construction & Engineering Pty Ltd')
    end

    it 'returns "Conocophillips Australia Pty Ltd" for names containing "Conocophillips"' do
      expect(described_class.new.call('Conocophillips')).to eq('Conocophillips Australia Pty Ltd')
    end

    it 'returns "Consolidated Properties Group" for names containing "Consolidated Properties Group" or equal to "Consolidated Properties"' do
      expect(described_class.new.call('Consolidated Properties Group')).to eq('Consolidated Properties Group')
      expect(described_class.new.call('Consolidated Properties')).to eq('Consolidated Properties Group')
    end

    it 'returns "Cooper Energy Ltd" for names containing "Cooper Energy Ltd" or equal to "Cooper Energy"' do
      expect(described_class.new.call('Cooper Energy Ltd')).to eq('Cooper Energy Ltd')
      expect(described_class.new.call('Cooper Energy')).to eq('Cooper Energy Ltd')
    end

    it 'returns "Delaware North" for names containing "Delaware North"' do
      expect(described_class.new.call('Delaware North')).to eq('Delaware North')
    end

    it 'returns "Dell Australia Pty Ltd" for names containing "Dell Australia" or "Dell Technologies"' do
      expect(described_class.new.call('Dell Australia')).to eq('Dell Australia Pty Ltd')
      expect(described_class.new.call('Dell Technologies')).to eq('Dell Australia Pty Ltd')
    end

    it 'returns "Diageo Australia Limited" for names containing "Diageo Australia"' do
      expect(described_class.new.call('Diageo Australia')).to eq('Diageo Australia Limited')
    end

    it 'returns "Droneshield Limited" for names containing "Droneshield"' do
      expect(described_class.new.call('Droneshield')).to eq('Droneshield Limited')
    end

    it 'returns "Echostar Global Australia Pty Ltd" for names containing "Echostar"' do
      expect(described_class.new.call('Echostar')).to eq('Echostar Global Australia Pty Ltd')
    end

    it 'returns "Edwards Lifesciences Pty Ltd" for names containing "Edwards Lifesciences" or "Edwards Life"' do
      expect(described_class.new.call('Edwards Lifesciences')).to eq('Edwards Lifesciences Pty Ltd')
      expect(described_class.new.call('Edwards Life')).to eq('Edwards Lifesciences Pty Ltd')
    end

    it 'returns "Elbit Systems of Australia P/L" for names containing "Elbit Systems of Australia"' do
      expect(described_class.new.call('Elbit Systems of Australia')).to eq('Elbit Systems of Australia P/L')
    end

    it 'returns "Electro Optic Systems Pty Ltd" for names containing "Electro Optic Systems"' do
      expect(described_class.new.call('Electro Optic Systems')).to eq('Electro Optic Systems Pty Ltd')
    end

    it 'returns "Eli Lilly Australia Pty Ltd" for names containing "Eli Lilly Australia" or equal to "Eli Lilly"' do
      expect(described_class.new.call('Eli Lilly Australia')).to eq('Eli Lilly Australia Pty Ltd')
      expect(described_class.new.call('Eli Lilly')).to eq('Eli Lilly Australia Pty Ltd')
    end

    it 'returns "Environmental Defense Fund" for names containing "Environmental Defense Fund"' do
      expect(described_class.new.call('Environmental Defense Fund')).to eq('Environmental Defense Fund')
    end

    it 'returns "Equinor Australia" for names containing "Equinor Australia" or equal to "Equinor"' do
      expect(described_class.new.call('Equinor Australia')).to eq('Equinor Australia')
      expect(described_class.new.call('Equinor')).to eq('Equinor Australia')
    end

    it 'returns "Ernst & Young" for names containing "Ernst & Young"' do
      expect(described_class.new.call('Ernst & Young')).to eq('Ernst & Young')
    end

    it 'returns "Eusa Pharma (Australia) Pty Ltd" for names containing "Eusa Pharma (Australia) Pty Ltd" or equal to "Eusa Pharma"' do
      expect(described_class.new.call('Eusa Pharma (Australia) Pty Ltd')).to eq('Eusa Pharma (Australia) Pty Ltd')
      expect(described_class.new.call('Eusa Pharma')).to eq('Eusa Pharma (Australia) Pty Ltd')
    end

    it 'returns "Expedia Australia Pty Ltd" for names containing "Expedia Australia Pty Ltd" or equal to "Expedia"' do
      expect(described_class.new.call('Expedia Australia Pty Ltd')).to eq('Expedia Australia Pty Ltd')
      expect(described_class.new.call('Expedia')).to eq('Expedia Australia Pty Ltd')
    end

    it 'returns "Field and Game Australia" for names containing "Field and Game Australia"' do
      expect(described_class.new.call('Field and Game Australia')).to eq('Field and Game Australia')
    end

    it 'returns "Football Australia" for names containing "Football Australia Limited" or equal to "Football Australia"' do
      expect(described_class.new.call('Football Australia Limited')).to eq('Football Australia')
      expect(described_class.new.call('Football Australia')).to eq('Football Australia')
    end

    it 'returns "Fortem Australia Limited" for names containing "Fortem Australia Limited" or equal to "Fortem Australia"' do
      expect(described_class.new.call('Fortem Australia Limited')).to eq('Fortem Australia Limited')
      expect(described_class.new.call('Fortem Australia')).to eq('Fortem Australia Limited')
    end

    it 'returns "Free TV Australia Limited" for names containing "Free TV Australia" or "FreeTV Australia"' do
      expect(described_class.new.call('Free TV Australia')).to eq('Free TV Australia Limited')
      expect(described_class.new.call('FreeTV Australia')).to eq('Free TV Australia Limited')
    end

    it 'returns "Frisk - Search Pty Ltd" for names containing "Frisk" and "Search"' do
      expect(described_class.new.call('Frisk Search')).to eq('Frisk - Search Pty Ltd')
      expect(described_class.new.call('Frisk and Search')).to eq('Frisk - Search Pty Ltd')
    end

    it 'returns "From the Fields Pharmaceuticals Australia Pty Ltd" for names containing "From The Fields"' do
      expect(described_class.new.call('From The Fields')).to eq('From the Fields Pharmaceuticals Australia Pty Ltd')
    end

    it 'returns "Fugro Australia Pty Ltd" for names containing "Fugro Australia" or equal to "Fugro"' do
      expect(described_class.new.call('Fugro Australia')).to eq('Fugro Australia Pty Ltd')
      expect(described_class.new.call('Fugro')).to eq('Fugro Australia Pty Ltd')
    end

    it 'returns "GB Energy Holdings Pty Ltd" for names containing "GB Energy Holdings" or equal to "GB Energy"' do
      expect(described_class.new.call('GB Energy Holdings')).to eq('GB Energy Holdings Pty Ltd')
      expect(described_class.new.call('GB Energy')).to eq('GB Energy Holdings Pty Ltd')
    end

    it 'returns "Gascoyne Gateway Limited" for names containing "Gascoyne Gateway Limited"' do
      expect(described_class.new.call('Gascoyne Gateway Limited')).to eq('Gascoyne Gateway Limited')
    end

    it 'returns "Gedeon Richter Australia Pty Ltd" for names containing "Gedeon Richter Australia"' do
      expect(described_class.new.call('Gedeon Richter Australia')).to eq('Gedeon Richter Australia Pty Ltd')
    end

    it 'returns "Gilmour Space Technologies Pty Ltd" for names containing "Gilmour Space Technologies"' do
      expect(described_class.new.call('Gilmour Space Technologies')).to eq('Gilmour Space Technologies Pty Ltd')
    end

    it 'returns "Gippsland Critical Minerals" for names containing "Gippsland Critical Minerals"' do
      expect(described_class.new.call('Gippsland Critical Minerals')).to eq('Gippsland Critical Minerals')
    end

    it 'returns "Glengarry Advisory Pty Ltd" for names containing "Glengarry Advisory"' do
      expect(described_class.new.call('Glengarry Advisory')).to eq('Glengarry Advisory Pty Ltd')
    end

    it 'returns "Golf Australia Limited" for names containing "Golf Australia Limited" or "Golf Australia Ltd"' do
      expect(described_class.new.call('Golf Australia Limited')).to eq('Golf Australia Limited')
      expect(described_class.new.call('Golf Australia Ltd')).to eq('Golf Australia Limited')
    end

    it 'returns "Google Australia Pty Ltd" for names containing "Google Australia"' do
      expect(described_class.new.call('Google Australia')).to eq('Google Australia Pty Ltd')
    end

    it 'returns "Group of 100" for names containing "Group of 100"' do
      expect(described_class.new.call('Group of 100')).to eq('Group of 100')
    end

    it 'returns "Gulanga Group" for names containing "Gulanga Group"' do
      expect(described_class.new.call('Gulanga Group')).to eq('Gulanga Group')
    end

    it 'returns "Heartland Solutions Group" for names containing "Heartland Solutions Group"' do
      expect(described_class.new.call('Heartland Solutions Group')).to eq('Heartland Solutions Group')
    end

    it 'returns "Holmes Institute" for names containing "Holmes Institute"' do
      expect(described_class.new.call('Holmes Institute')).to eq('Holmes Institute')
    end

    it 'returns "Holmwood Highgate Pty Ltd" for names containing "Holmwood Highgate"' do
      expect(described_class.new.call('Holmwood Highgate')).to eq('Holmwood Highgate Pty Ltd')
    end

    it 'returns "Idemitsu Australia Pty Ltd" for names containing "Idemitsu Australia"' do
      expect(described_class.new.call('Idemitsu Australia')).to eq('Idemitsu Australia Pty Ltd')
    end

    it 'returns "Inghams Group Limited" for names containing "Inghams Group Limited" or equal to "Inghams"' do
      expect(described_class.new.call('Inghams Group Limited')).to eq('Inghams Group Limited')
      expect(described_class.new.call('Inghams')).to eq('Inghams Group Limited')
    end

    it 'returns "Insurance Council of Australia" for names containing "Insurance Council of Australia"' do
      expect(described_class.new.call('Insurance Council of Australia')).to eq('Insurance Council of Australia')
    end

    it 'returns "Intech Strategies P/L" for names containing "Intech Strategies"' do
      expect(described_class.new.call('Intech Strategies')).to eq('Intech Strategies P/L')
    end

    it 'returns "Ipsen Pty Ltd" for names containing "Ipsen Pty Ltd" or equal to "Ipsen"' do
      expect(described_class.new.call('Ipsen Pty Ltd')).to eq('Ipsen Pty Ltd')
      expect(described_class.new.call('Ipsen')).to eq('Ipsen Pty Ltd')
    end

    it 'returns "Israel Aerospace Industries Limited" for names containing "Israel Aerospace Industries Limited" or equal to "Ipsen"' do
      expect(described_class.new.call('Israel Aerospace Industries Limited')).to eq('Israel Aerospace Industries Limited')
    end

    it 'returns "JERA Australia Pty Ltd" for names containing "JERA Australia" or equal to "Jera"' do
      expect(described_class.new.call('JERA Australia')).to eq('JERA Australia Pty Ltd')
      expect(described_class.new.call('Jera')).to eq('JERA Australia Pty Ltd')
    end

    it 'returns "Jellinbah Group" for names containing "Jellinbah Group"' do
      expect(described_class.new.call('Jellinbah Group')).to eq('Jellinbah Group')
    end

    it 'returns "Johnson & Johnson Medical" for names containing "Johnson & Johnson Medical"' do
      expect(described_class.new.call('Johnson & Johnson Medical')).to eq('Johnson & Johnson Medical')
      expect(described_class.new.call('Johnson And Johnson Medical')).to eq('Johnson & Johnson Medical')
    end

    it 'returns "Johnson & Johnson Pty Ltd" for names containing "Johnson & Johnson"' do
      expect(described_class.new.call('Johnson & Johnson')).to eq('Johnson & Johnson Pty Ltd')
      expect(described_class.new.call('Johnson And Johnson')).to eq('Johnson & Johnson Pty Ltd')
    end

    it 'returns "KPMG Australia" for names containing "KPMG Australia" or equal to "KPMG"' do
      expect(described_class.new.call('KPMG Australia')).to eq('KPMG Australia')
      expect(described_class.new.call('KPMG')).to eq('KPMG Australia')
    end

    it 'returns "Kimberly-Clark Australia Pty Ltd" for names containing "Kimberly-Clark Australia" or "KimberlyClark"' do
      expect(described_class.new.call('Kimberly-Clark Australia')).to eq('Kimberly-Clark Australia Pty Ltd')
      expect(described_class.new.call('KimberlyClark')).to eq('Kimberly-Clark Australia Pty Ltd')
    end

    it 'returns "L3 Harris Technologies" for names containing "L3 Harris Technologies" or "L3Harris Technologies"' do
      expect(described_class.new.call('L3 Harris Technologies')).to eq('L3 Harris Technologies')
      expect(described_class.new.call('L3Harris Technologies')).to eq('L3 Harris Technologies')
    end

    it 'returns "Lendlease Australia Pty Ltd" for names containing "Lendlease Australia" or "Lendlease Pty Ltd"' do
      expect(described_class.new.call('Lendlease Australia')).to eq('Lendlease Australia Pty Ltd')
      expect(described_class.new.call('Lendlease Pty Ltd')).to eq('Lendlease Australia Pty Ltd')
    end

    it 'returns "Lion Pty Ltd" for names equal to "lion"' do
      expect(described_class.new.call('lion')).to eq('Lion Pty Ltd')
    end

    it 'returns "Lockheed Martin Australia Pty Ltd" for names containing "Lockheed Martin Australia"' do
      expect(described_class.new.call('Lockheed Martin Australia')).to eq('Lockheed Martin Australia Pty Ltd')
    end

    it 'returns "Matrix Composites & Engineering" for names containing "Matrix Composites & Engineering"' do
      expect(described_class.new.call('Matrix Composites & Engineering')).to eq('Matrix Composites & Engineering')
    end

    it 'returns "Merck Healthcare" for names containing "Merck Healthcare"' do
      expect(described_class.new.call('Merck Healthcare')).to eq('Merck Healthcare')
    end

    it 'returns "Metallicum Minerals Corporation" for names containing "Metallicum Minerals Corporation"' do
      expect(described_class.new.call('Metallicum Minerals Corporation')).to eq('Metallicum Minerals Corporation')
    end

    it 'returns "National Retail Association Limited" for names containing "National Retail Association"' do
      expect(described_class.new.call('National Retail Association')).to eq('National Retail Association Limited')
    end

    it 'returns "Nestle Australia" for names containing "Nestle Australia"' do
      expect(described_class.new.call('Nestle Australia')).to eq('Nestle Australia')
    end

    it 'returns "Netapp Pty Ltd" for names containing "Netapp Pty Ltd" or equal to "Netapp"' do
      expect(described_class.new.call('Netapp Pty Ltd')).to eq('Netapp Pty Ltd')
      expect(described_class.new.call('Netapp')).to eq('Netapp Pty Ltd')
    end

    it 'returns "Novo Nordisk Pharmaceuticals Pty Ltd" for names containing "Novo Nordisk Pharmaceuticals"' do
      expect(described_class.new.call('Novo Nordisk Pharmaceuticals')).to eq('Novo Nordisk Pharmaceuticals Pty Ltd')
    end

    it 'returns "Orion Sovereign Group Pty Ltd" for names containing "Orion Sovereign Group"' do
      expect(described_class.new.call('Orion Sovereign Group')).to eq('Orion Sovereign Group Pty Ltd')
    end

    it 'returns "PainAustralia Limited" for names containing "PainAustralia"' do
      expect(described_class.new.call('PainAustralia')).to eq('PainAustralia Limited')
    end

    it 'returns "Paintback Limited" for names containing "Paintback"' do
      expect(described_class.new.call('Paintback')).to eq('Paintback Limited')
    end

    it 'returns "Pathology Technology Australia" for names containing "Pathology Technology Australia"' do
      expect(described_class.new.call('Pathology Technology Australia')).to eq('Pathology Technology Australia')
    end

    it 'returns "Penten Pty Ltd" for names containing "Penten Pty Ltd" or equal to "Penten"' do
      expect(described_class.new.call('Penten Pty Ltd')).to eq('Penten Pty Ltd')
      expect(described_class.new.call('Penten')).to eq('Penten Pty Ltd')
    end

    it 'returns "Playgroups Australia" for names containing "Playgroups Australia"' do
      expect(described_class.new.call('Playgroups Australia')).to eq('Playgroups Australia')
    end

    it 'returns "Pratt Holdings Pty Ltd" for names containing "Pratt Holdings"' do
      expect(described_class.new.call('Pratt Holdings')).to eq('Pratt Holdings Pty Ltd')
    end

    it 'returns "RES Australia Pty Ltd" for names containing "RES Australia" or "RES Australia Pty Ltd"' do
      expect(described_class.new.call('RES Australia')).to eq('RES Australia Pty Ltd')
      expect(described_class.new.call('RES Australia Pty Ltd')).to eq('RES Australia Pty Ltd')
    end

    it 'returns "RZ Resources Limited" for names containing "RZ Resources Limited" or "RZ Resources Ltd"' do
      expect(described_class.new.call('RZ Resources Limited')).to eq('RZ Resources Limited')
      expect(described_class.new.call('RZ Resources Ltd')).to eq('RZ Resources Limited')
    end

    it 'returns "Ramsay Health Care Limited" for names containing "Ramsay Health Care"' do
      expect(described_class.new.call('Ramsay Health Care')).to eq('Ramsay Health Care Limited')
    end

    it 'returns "Rare Cancers Australia" for names containing "Rare Cancers Australia"' do
      expect(described_class.new.call('Rare Cancers Australia')).to eq('Rare Cancers Australia')
    end

    it 'returns "Ryman Healthcare (Australia) Pty Ltd" for names containing "Ryman Healthcare Australia" or equal to "ryman healthcare"' do
      expect(described_class.new.call('Ryman Healthcare Australia')).to eq('Ryman Healthcare (Australia) Pty Ltd')
      expect(described_class.new.call('ryman healthcare')).to eq('Ryman Healthcare (Australia) Pty Ltd')
    end

    it 'returns "SA Milgate and Associates Pty Ltd" for names containing "SA Milgate and Associates"' do
      expect(described_class.new.call('SA Milgate and Associates')).to eq('SA Milgate and Associates Pty Ltd')
    end

    it 'returns "ST John of GOD Healthcare" for names containing "ST John of GOD Healthcare" or "ST John of GOD Health Care"' do
      expect(described_class.new.call('ST John of GOD Healthcare')).to eq('ST John of GOD Healthcare')
      expect(described_class.new.call('ST John of GOD Health Care')).to eq('ST John of GOD Healthcare')
    end

    it 'returns "Saab Australia Pty Ltd" for names containing "Saab Australia Pty Ltd" or equal to "saab"' do
      expect(described_class.new.call('Saab Australia Pty Ltd')).to eq('Saab Australia Pty Ltd')
      expect(described_class.new.call('saab')).to eq('Saab Australia Pty Ltd')
    end

    it 'returns "Settlement Services International" for names containing "Settlement Services International"' do
      expect(described_class.new.call('Settlement Services International')).to eq('Settlement Services International')
    end

    it 'returns "Shop Distributive & Allied Employees Association - National" for names containing "Shop Distributive & Allied Employees Association - National" or similar variations' do
      expect(described_class.new.call('Shop Distributive & Allied Employees Association - National')).to eq("Shop Distributive & Allied Employees Association - National'")
      expect(described_class.new.call('Shop and Allied Employees Association National')).to eq("Shop Distributive & Allied Employees Association - National'")
    end

    it 'returns "SMEC Australia Pty Ltd" for names containing "SMEC Australia"' do
      expect(described_class.new.call('SMEC Australia')).to eq('SMEC Australia Pty Ltd')
    end

    it 'returns "Sovori Pty Ltd ATF the Sovori Trust" for names containing "Sovori Pty Ltd"' do
      expect(described_class.new.call('Sovori Pty Ltd')).to eq('Sovori Pty Ltd ATF the Sovori Trust')
    end

    it 'returns "Space Machines Company" for names containing "Space Machines Company"' do
      expect(described_class.new.call('Space Machines Company')).to eq('Space Machines Company')
    end

    it 'returns "Speedcast Australia Pty Ltd" for names containing "Speedcast Australia Pty Ltd" or equal to "Speedcast"' do
      expect(described_class.new.call('Speedcast Australia Pty Ltd')).to eq('Speedcast Australia Pty Ltd')
      expect(described_class.new.call('Speedcast')).to eq('Speedcast Australia Pty Ltd')
    end

    it 'returns "Spirits & Cocktails Australia" for names containing "Spirits & Cocktails Australia" or "Spirits and Cocktails Australia"' do
      expect(described_class.new.call('Spirits & Cocktails Australia')).to eq('Spirits & Cocktails Australia')
      expect(described_class.new.call('Spirits and Cocktails Australia')).to eq('Spirits & Cocktails Australia')
    end

    it 'returns "Springfield City Group" for names containing "Springfield City Group"' do
      expect(described_class.new.call('Springfield City Group')).to eq('Springfield City Group')
    end

    it 'returns "Standbyu Foundation" for names containing "Standbyu Foundation"' do
      expect(described_class.new.call('Standbyu Foundation')).to eq('Standbyu Foundation')
    end

    it 'returns "Stryker Australia Pty Ltd" for names containing "Stryker Australia Pty Ltd" or equal to "stryker"' do
      expect(described_class.new.call('Stryker Australia Pty Ltd')).to eq('Stryker Australia Pty Ltd')
      expect(described_class.new.call('stryker')).to eq('Stryker Australia Pty Ltd')
    end

    it 'returns "Strzelecki Holdings Pty Ltd" for names containing "Strzelecki Holdings Pty Ltd" or "Strzelecki Holding Pty Ltd"' do
      expect(described_class.new.call('Strzelecki Holdings Pty Ltd')).to eq('Strzelecki Holdings Pty Ltd')
      expect(described_class.new.call('Strzelecki Holding Pty Ltd')).to eq('Strzelecki Holdings Pty Ltd')
    end

    it 'returns "Sumitomo Corporation" for names containing "Sumitomo Corporation" or "Sumitom Corporation"' do
      expect(described_class.new.call('Sumitomo Corporation')).to eq('Sumitomo Corporation')
      expect(described_class.new.call('Sumitom Corporation')).to eq('Sumitomo Corporation')
    end

    it 'returns "Ted Noffs Foundation" for names containing "TED Noffs Foundation"' do
      expect(described_class.new.call('TED Noffs Foundation')).to eq('Ted Noffs Foundation')
    end

    it 'returns "Tellus Holdings Ltd" for names containing "Tellus Holdings"' do
      expect(described_class.new.call('Tellus Holdings')).to eq('Tellus Holdings Ltd')
    end

    it 'returns "Telstra Corporation" for names containing "Telstra Corporation" or equal to "telstra"' do
      expect(described_class.new.call('Telstra Corporation')).to eq('Telstra Corporation')
      expect(described_class.new.call('telstra')).to eq('Telstra Corporation')
    end

    it 'returns "The Alannah & Madeline Foundation" for names containing "The Alannah & Madeline Foundation" or "The Alannah and Madeline Foundation"' do
      expect(described_class.new.call('The Alannah & Madeline Foundation')).to eq('The Alannah & Madeline Foundation')
      expect(described_class.new.call('The Alannah and Madeline Foundation')).to eq('The Alannah & Madeline Foundation')
    end

    it 'returns "The Premier Communications Group" for names containing "The Premier Communications Group"' do
      expect(described_class.new.call('The Premier Communications Group')).to eq('The Premier Communications Group')
    end

    it 'returns "The Union Education Foundation" for names containing "The Union Education Foundation"' do
      expect(described_class.new.call('The Union Education Foundation')).to eq('The Union Education Foundation')
    end

    it 'returns "Trademark Group of Companies" for names containing "Trademark Group of Companies"' do
      expect(described_class.new.call('Trademark Group of Companies')).to eq('Trademark Group of Companies')
    end

    it 'returns "Trafigura" for names containing "Trafigura Pte Ltd" or equal to "trafigura"' do
      expect(described_class.new.call('Trafigura Pte Ltd')).to eq('Trafigura')
      expect(described_class.new.call('trafigura')).to eq('Trafigura')
    end

    it 'returns "Tronox Limited" for names containing "Tronox Limited" or "Tronox Ltd"' do
      expect(described_class.new.call('Tronox Limited')).to eq('Tronox Limited')
      expect(described_class.new.call('Tronox Ltd')).to eq('Tronox Limited')
    end

    it 'returns "UCB Australia Pty Ltd" for names containing "UCB Australia Pty Ltd" or "UCB Australia Proprietary Limited"' do
      expect(described_class.new.call('UCB Australia Pty Ltd')).to eq('UCB Australia Pty Ltd')
      expect(described_class.new.call('UCB Australia Proprietary Limited')).to eq('UCB Australia Pty Ltd')
    end

    it 'returns "Uber Australia Pty Ltd" for names containing "Uber Australia Pty Ltd" or equal to "uber"' do
      expect(described_class.new.call('Uber Australia Pty Ltd')).to eq('Uber Australia Pty Ltd')
      expect(described_class.new.call('uber')).to eq('Uber Australia Pty Ltd')
    end

    it 'returns "Van Dairy Ltd" for names containing "Van Dairy Ltd" or "vanmilk"' do
      expect(described_class.new.call('Van Dairy Ltd')).to eq('Van Dairy Ltd')
      expect(described_class.new.call('vanmilk')).to eq('Van Dairy Ltd')
    end

    it 'returns "Varley Rafael Australia" for names containing "Varley Rafael Australia" or equal to "varley rafael"' do
      expect(described_class.new.call('Varley Rafael Australia')).to eq('Varley Rafael Australia')
      expect(described_class.new.call('varley rafael')).to eq('Varley Rafael Australia')
    end

    it 'returns "Verbrec Ltd" for names containing "Verbrec Ltd" or "Verbrec Limited" or equal to "verbrec"' do
      expect(described_class.new.call('Verbrec Ltd')).to eq('Verbrec Ltd')
      expect(described_class.new.call('Verbrec Limited')).to eq('Verbrec Ltd')
      expect(described_class.new.call('verbrec')).to eq('Verbrec Ltd')
    end

    it 'returns "Verdant Minerals" for names containing "Verdant Minerals"' do
      expect(described_class.new.call('Verdant Minerals')).to eq('Verdant Minerals')
    end

    it 'returns "Vertex Pharmaceuticals Australia Pty Ltd" for names containing "Vertex Pharmaceuticals Australia"' do
      expect(described_class.new.call('Vertex Pharmaceuticals Australia')).to eq('Vertex Pharmaceuticals Australia Pty Ltd')
    end

    it 'returns "Victorian Hydrogen and Ammonia Industries Limited" for names containing "Victorian Hydrogen and Ammonia Industries" or "Victorian Hydrogen & Ammonia Industries"' do
      expect(described_class.new.call('Victorian Hydrogen and Ammonia Industries')).to eq('Victorian Hydrogen and Ammonia Industries Limited')
      expect(described_class.new.call('Victorian Hydrogen & Ammonia Industries')).to eq('Victorian Hydrogen and Ammonia Industries Limited')
    end

    it 'returns "Wesfarmers Limited" for names containing "Wesfarmers Limited" or "Wesfarmers Ltd" or equal to "wesfarmers"' do
      expect(described_class.new.call('Wesfarmers Limited')).to eq('Wesfarmers Limited')
      expect(described_class.new.call('Wesfarmers Ltd')).to eq('Wesfarmers Limited')
      expect(described_class.new.call('wesfarmers')).to eq('Wesfarmers Limited')
    end

    it 'returns "Westpac Banking Corporation" for names containing "Westpac Banking Corporation" or equal to "westpac"' do
      expect(described_class.new.call('Westpac Banking Corporation')).to eq('Westpac Banking Corporation')
      expect(described_class.new.call('westpac')).to eq('Westpac Banking Corporation')
    end

    # it 'returns "Your (Solutions|Solution) Compounding Pharmacy" for names containing "Your Solutions Compounding Pharmacy"' do
    #   expect(described_class.new('Your Solutions Compounding Pharmacy').call).to eq('Your (Solutions|Solution) Compounding Pharmacy')
    # end

    it 'returns "Yumbah Aquaculture" for names containing "Yumbah Aquaculture"' do
      expect(described_class.new.call('Yumbah Aquaculture')).to eq('Yumbah Aquaculture')
    end

    it 'returns "Clubs Australia" for names containing "ClubsAustralia Inc"' do
      expect(described_class.new.call('ClubsAustralia Inc')).to eq('Clubs Australia')
    end

    it 'returns "Idameneo (No 123) Pty Ltd" for names containing "Idameneo No 123"' do
      expect(described_class.new.call('Idameneo No 123')).to eq('Idameneo (No 123) Pty Ltd')
    end

    it 'returns "Schaffer Corporation Limited" for names containing "Schaffer Corporation Limited" or "Schaffer Corporation Ltd"' do
      expect(described_class.new.call('Schaffer Corporation Limited')).to eq('Schaffer Corporation Limited')
      expect(described_class.new.call('Schaffer Corporation Ltd')).to eq('Schaffer Corporation Limited')
    end

    it 'returns "The Union Education Foundation" for names containing "Union Education Foundation"' do
      expect(described_class.new.call('Union Education Foundation')).to eq('The Union Education Foundation')
    end

    it 'returns "Tamboran Resources Limited" for names containing "Tamboran Resources"' do
      expect(described_class.new.call('Tamboran Resources')).to eq('Tamboran Resources Limited')
    end

    it 'returns "Paladin Group" for names containing "Paladin Group"' do
      expect(described_class.new.call('Paladin Group')).to eq('Paladin Group')
    end

    it 'returns "Qube Ports" for names containing "Qube Ports"' do
      expect(described_class.new.call('Qube Ports')).to eq('Qube Ports')
    end

    it 'returns "Australian Energy Producers" for names containing "APPEA" or "Australian Energy Producers"' do
      expect(described_class.new.call('APPEA')).to eq('Australian Energy Producers')
      expect(described_class.new.call('Australian Energy Producers')).to eq('Australian Energy Producers')
    end

    context 'for smaller political parties' do
      it 'returns "Liberal Democratic Party" for names containing "Liberal Democrat"' do
        expect(described_class.new.call('Liberal Democrat')).to eq('Liberal Democratic Party')
        expect(described_class.new.call('Liberal Democratic Party')).to eq('Liberal Democratic Party')
      end

      it 'returns "Shooters, Fishers and Farmers Party" for names containing "Shooters, Fishers and Farmers"' do
        expect(described_class.new.call('Shooters, Fishers and Farmers')).to eq('Shooters, Fishers and Farmers Party')
      end

      it 'returns "Citizens Party" for names containing "Citizens Party" or "CEC"' do
        expect(described_class.new.call('Citizens Party')).to eq('Citizens Party')
        expect(described_class.new.call('CEC')).to eq('Citizens Party')
      end

      it 'returns "Sustainable Australia Party" for names containing "Sustainable Australia"' do
        expect(described_class.new.call('Sustainable Australia')).to eq('Sustainable Australia Party')
      end

      it 'returns "Centre Alliance" for names containing "Centre Alliance"' do
        expect(described_class.new.call('Centre Alliance')).to eq('Centre Alliance')
      end

      it 'returns "The Local Party of Australia" for names containing "The Local Party of Australia"' do
        expect(described_class.new.call('The Local Party of Australia')).to eq('The Local Party of Australia')
      end

      it 'returns "Katter Australia Party" for names containing "Katter Australia" or "KAP"' do
        expect(described_class.new.call('Katter Australia')).to eq('Katter Australia Party')
        expect(described_class.new.call('KAP')).to eq('Katter Australia Party')
      end

      it 'returns "Australian Conservatives" for names containing "Australian Conservatives"' do
        expect(described_class.new.call('Australian Conservatives')).to eq('Australian Conservatives')
      end

      it 'returns "Federal Independents" for names containing "Independent Fed"' do
        expect(described_class.new.call('Independent Fed')).to eq('Federal Independents')
      end

      it 'returns "Waringah Independents" for names containing "Warringah Independent" or "Waringah Independant"' do
        expect(described_class.new.call('Warringah Independent')).to eq('Waringah Independents')
        expect(described_class.new.call('Waringah Independant')).to eq('Waringah Independents')
      end

      it 'returns "Lambie Network" for names containing "Lambie"' do
        expect(described_class.new.call('Lambie')).to eq('Lambie Network')
      end

      it 'returns "United Australia Party" for names containing "United Australia Party" or "United Australia Federal"' do
        expect(described_class.new.call('United Australia Party')).to eq('United Australia Party')
        expect(described_class.new.call('United Australia Federal')).to eq('United Australia Party')
      end

      it 'returns "Pauline Hanson\'s One Nation" for names containing "Pauline Hanson" or "One Nation"' do
        expect(described_class.new.call('Pauline Hanson')).to eq("Pauline Hanson's One Nation")
        expect(described_class.new.call('One Nation')).to eq("Pauline Hanson's One Nation")
      end
    end

    context 'for liberal party' do
      it 'returns lib federal' do
        expect(described_class.new.call('Liberal Party Menzies Research Centre')).to eq('Liberals (Federal)')
      end
    end
  end
end
