class TemplatesController < ApplicationController
  def new
    @template = Template.new
  end

  def create
    file = params.dig(:template, :docx)
    if file.blank?
      flash[:alert] = "Please upload a .docx file"
      return redirect_to root_path
    end

    @template = Template.new
    @template.docx.attach(file)
    @template.save!

    redirect_to template_path(@template)
  end

  def show
    @template = Template.find(params[:id])
    extractor = DocxPlaceholderService.new(@template.docx)
    @placeholders = extractor.placeholders
  end

  def generate
    @template = Template.find(params[:id])

    extractor = DocxPlaceholderService.new(@template.docx)
    allowed_keys = extractor.placeholders

    raw_values = params.fetch(:values, {}).permit(allowed_keys).to_h

    generator = DocxPlaceholderService.new(@template.docx)
    out = generator.render(raw_values)
    
    send_data out,
      filename: "generated-#{@template.id}.docx",
      type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  end
end
