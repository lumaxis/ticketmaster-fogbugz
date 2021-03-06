module TicketMaster::Provider
  module Fogbugz
    # Ticket class for ticketmaster-fogbugz
    #
    
    class Ticket < TicketMaster::Provider::Base::Ticket
      #API = Fogbugz::Ticket # The class to access the api's tickets
      # declare needed overloaded methods here
      
      def initialize(*object)
        if object.first
          object = object.first
          unless object.is_a? Hash
            @system_data = {:client => object}
            hash = {:id => object['ixBug'],
              :title => object['sTitle'],
              :category => object['sCategory'],
              :description => object['sLatestTextSummary'], 
              :status => object['sStatus'],
              :project_id => object['ixProject'],
              :resolution => nil, 
              :requestor => nil,
              :priority => object['sPriority'],
              :assignee => object['sPersonAssignedTo'],
              :created_at => nil,
              :updated_at => object['dtLastUpdated']}
          else
            hash = object
          end
          super(hash)
        end
      end

      def id
        self['ixBug'].to_i
      end

      def title
        self['sTitle']
      end

      def description 
        self['LatestTextSummary']
      end

      def project_id
        self['ixProject'].to_i
      end

      def resolution
        nil
      end

      def status
        self['sStatus']
      end

      def requestor
        nil
      end

      def priority
        self['sPriority']
      end

      def assignee
        self['sPersonAssignedTo']
      end

      def created_at
        nil
      end

      def updated_at
        Time.parse(self['dtLastUpdated'])
      end

      def comments(*options)
        []
        warn "Fogbugz API doesn't support comments"
      end

      def comment(*options)
        nil
        warn "Fogbugz API doesn't support comments"
      end
      
      def self.create(*options)
        attributes = options.first
        issue = TicketMaster::Provider::Fogbugz.api.command(:new, {
          :ixProject => attributes[:project_id], 
          :sTitle => attributes[:title], 
          :sEvent => attributes[:description], 
          :sCategory => attributes[:category],
          :sArea => attributes[:area]
        })
        return nil if issue["case"].nil? and issue["case"]["ixBug"].nil?
        return self.new(issue["case"])
      end

      def self.find(project_id, options)
        if options.first.is_a? Array
          self.find_all(project_id).select do |ticket|
            options.first.any? { |id| ticket.id == id }
          end
        elsif options.first.is_a? Hash
          self.find_by_attributes(project_id, options.first)
        else
          self.find_all(project_id)
        end
      end

      def self.find_by_id(project_id, id)
        self.find_all(project_id).select { |ticket| ticket.id == id }.first
      end

      def self.find_by_attributes(project_id, attributes = {})
        search_by_attribute(self.find_all(project_id), attributes)
      end

      def self.find_all(project_id)
        tickets = []
        TicketMaster::Provider::Fogbugz.api.command(:search, :q => "project:=#{project_id}", :cols =>"dtLastUpdated,ixBug,sStatus,sTitle,sLatestTextSummary,ixProject,sProject,sPersonAssignedTo,sPriority").each do |ticket|
          tickets << ticket[1]["case"]
        end
        tickets.flatten.map { |xticket| self.new xticket }
      end
    end
  end
end
