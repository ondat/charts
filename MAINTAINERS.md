# Maintaining these charts

These charts are deployed automatically on merge. Each time a chart is changed, this is detected and the updated version is pushed up automatically,
do take care to increment the chart version when making updates.

Note that the umbrella chart can only be updated to use newer sub-chart versions if those sub-charts have already been updated - this must be done in
a separate PR, after the subchart itself has been updated. Otherwise, the Github Action used for continuous deployment will not run successfully.
