
class FindCaseView extends Backbone.View

  events:
    "keyup #caseId": "search"

  render: =>
    @$el.html "
      Case ID: <input id='caseId'/>
      <div id='results'/>
    "

  search: =>
    Coconut.database.query "cases",
      startkey: @$("#caseId").val()
      limit: 30
    .then (result) =>
      @$("#results").html "
        <ul>
          #{
            (for caseId in _(result.rows).chain().pluck("key").unique().value()
              if caseId is @$("#caseId").val() and caseId.length is 6
                Coconut.router.navigate "show/case/#{caseId}", trigger: true
              "<li><a href='#show/case/#{caseId}'>#{caseId}</a></li>"
            ).join("\n")
          }
        </ul>
      "

module.exports = FindCaseView
