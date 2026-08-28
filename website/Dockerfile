# MyReciBook website — static bundle behind nginx.
# Build context expects .output/public to exist (run `pnpm generate` first);
# deploy-staging.sh handles the sequence.
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY .output/public /usr/share/nginx/html
EXPOSE 8080
